import
  pkg/karax/[karax, kbase, karaxdsl, vdom, kdom],
  pkg/matrix,
  pkg/nodejs/jsindexeddb,
  std/[asyncjs, tables, json, jsffi, enumerate],
  shared, indexeddb
from std/sugar import `=>`

const
  dbName = "simple-matrix-client"
  homeserver = "https://matrix.org"

var
  db: IndexedDB = newIndexedDB()
  storedUsers: seq[User]
  globalClientView = ClientView.signin
  globalMenuView = MenuView.menu
  chatInfoView: InfoView = InfoView.none
  client = newAsyncMatrixClient(homeserver, token)
  currentUserId: string
  syncResp: SyncRes
  roomStateResp: RoomStateRes
  selectedChat: string

proc setSyncView(res: Syncres) =
  syncResp = res
  globalClientView = ClientView.chat
  redraw()

proc initialSync() {.async.} =
  globalMenuView = MenuView.syncing
  redraw()
  await client.sync()
    .then((syncResp: SyncRes) => setSyncView syncResp)

proc login =
  proc loginMatrix(homeserver, username, password: string) {.async.} =
    client = newAsyncMatrixClient(homeserver)
    let loginRes: LoginRes = await client.login(username, password)
    currentUserId = loginRes.userId
    client.setToken loginRes.accessToken
    discard initialSync()
    discard db.storeToken(currentUserId, homeserver, loginRes.accessToken)

  let
    homeserver = $getElementById("homeserver").value
    username = $getElementById("username").value
    password = $getElementById("password").value

  discard loginMatrix(homeserver, username, password)

proc register =
  proc registerMatrix(homeserver, password: string) {.async.} =
    client = newAsyncMatrixClient(homeserver)
    let regRes: RegisterRes = await client.registerGuest(password)
    currentUserId = regRes.userId
    client.setToken regRes.accessToken
    discard initialSync()
    discard db.storeToken(currentUserId, homeserver, regRes.accessToken)

  let
    homeserver = $getElementById("homeserver").value
    password = $getElementById("password").value
  discard registerMatrix(homeserver, password)

proc renderLogin*: Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      h3:
        text "Login:"
      input(id = "homeserver", class = "login-input", `type` = "text", onkeyupenter = login, value = "https://matrix.org", placeholder = "https://homeserver.org")
      input(id = "username", class = "login-input", `type` = "text", onkeyupenter = login, placeholder = "username")
      input(id = "password", class = "login-input", `type` = "password", onkeyupenter = login, placeholder = "password")
      button(id = "login", class = "text-button", onclick = login):
        text "Login"

proc validate(homeserver, token: string) {.async.} =
  client = newAsyncMatrixClient(homeserver)
  client.setToken token
  try:
    let whoAmIResp = await client.whoAmI()
    discard initialSync()
  except MatrixError:
    echo "bad token!"

proc getUsers {.async.} =
  let objStore = await indexeddb.getAll(db, "user".cstring)
  storedUsers = to(objStore, seq[User])
  redraw()

proc renderMenu*: Vnode =
  if storedUsers == @[]:
    discard getUsers()
  result = buildHtml:
    tdiv(class = "modal"):
      for user in storedUsers:
        button(id = kstring(user.userId), class = "signed-in-user"):
          text user.userId
          proc onclick() = discard validate($user.homeserver, $user.token)

      button(id = "signin", class = "text-button"):
        text "Sign-in"
        proc onclick() = globalMenuView = MenuView.loginView
      p:
        text "or"
      button(id = "register", class = "text-button"):
        text "Register as Guest"
        proc onclick() = globalMenuView = MenuView.registerView

proc renderRegister*: Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      h3:
        text "Register as guest:"
      input(id = "homeserver", class = "login-input", `type` = "text", onkeyupenter = register, value = "https://matrix.org", placeholder = "https://homeserver.org")
      input(id = "password", class = "login-input", `type` = "password", onkeyupenter = register, placeholder = "password")
      button(id = "register", class = "text-button", onclick = register):
        text "Register"

proc renderLoader*(message: string): Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      h3:
        text message
      img(id = "spinner", src = "/public/assets/spinner.svg")

proc signinModal: Vnode =
  result = buildHtml:
    tdiv(class = "container"):
      case globalMenuView:
      of MenuView.menu:
        renderMenu()
      of MenuView.loginView:
        renderLogin()
      of MenuView.registerView:
        renderRegister()
      of MenuView.syncing:
        renderLoader("Initial sync...")

proc renderRoomMembers(members: seq[StateEvent]): Vnode =
  result = buildHtml:
    tdiv(id = "members"):
      p(class = "heading"):
        text "Members:"
      tdiv(class = "list"):
        for member in members:
          p(id = "chat-participant"):
            text member.content["displayname"].getStr()

proc renderRoomState(roomStateResp: RoomStateRes): Vnode =
  var
    chatName: string
    members: seq[StateEvent]

  if roomStateResp.events.len != 0:
    for stateEv in roomStateResp.events:
      if stateEv.`type` == "m.room.member":
        members &= stateEv
      elif stateEv.`type` == "m.room.name":
        chatName = stateEv.content["name"].getStr()

  result = buildHtml:
    tdiv(id = "chat-information"):
      tdiv(id = "chat-profile"):
        h4(id = "chat-name"):
          text chatName
      renderRoomMembers(members)

proc saveRoomState(res: RoomStateRes) =
  roomStateResp = res
  chatInfoView = InfoView.some
  redraw()

proc getMatrixRoomState(roomId: string) {.async.} =
  await client.getRoomState(roomId)
    .then((resp: RoomStateRes) => (saveRoomState resp))

proc chatInfo*(roomId: string = ""): Vnode =
  if roomId == "":
    chatInfoView = InfoView.none
  else:
    if roomStateResp == RoomStateRes():
      chatInfoView = InfoView.loading
      discard getMatrixRoomState(roomId)
  result = buildHtml:
    tdiv(id = "info-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chat Information"
      case chatInfoView:
      of InfoView.none:
        tdiv(class = "modal"):
          h3:
            text "No chat selected."
      of InfoView.loading:
        renderLoader("Loading...")
      of InfoView.some:
        renderRoomState(roomStateResp)

proc onChatClick(ev: kdom.Event; n: VNode) =
  selectedChat = $n.id
  redraw()

proc renderJoinedRooms(joinedRooms: Table[string, JoinedRoom]): Vnode =
  # TODO: Add code to detect whether there is an active overflow and set the last-chat class
  result = buildHtml:
    tdiv(id = "chats", class = "list"):
      for i, (id, room) in enumerate joinedRooms.pairs:
        if i == joinedRooms.len - 1:
          button(class = "last-chat", id = kstring(id), onclick = onChatClick):
            text id
        else:
          button(class = "chat", id = kstring(id), onclick = onChatClick):
            text id

proc chatList*(syncResp: SyncRes): Vnode =
  result = buildHtml:
    tdiv(id = "list-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chats"
      renderJoinedRooms(syncResp.rooms.join)

proc createDom: VNode =
  result = buildHtml:
    tdiv:
      headerSection()
      case globalClientView:
      of ClientView.signin:
        main:
          signinModal()
      of ClientView.chat:
        main:
          chatList(syncResp)
          chatPane(currentUserId, syncResp.rooms.join[selectedChat])
          chatInfo(selectedChat)
      footerSection()

setRenderer createDom
