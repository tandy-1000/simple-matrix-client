import
  pkg/karax/[karax, kbase, karaxdsl, vdom, kdom],
  pkg/matrix,
  pkg/nodejs/jsindexeddb,
  std/[asyncjs, tables, json, jsffi, enumerate, times],
  shared
from std/sugar import `=>`, collect

const
  dbName = "simple-matrix-client"
  homeserver = "https://matrix.org"

var
  db: IndexedDB = newIndexedDB()
  dbOptions = IDBOptions(keyPath: "userId")
  client = newAsyncMatrixClient(homeserver = homeserver)
  globalClientView = ClientView.signin
  globalMenuView = MenuView.menu
  chatInfoView: ChatInfoView = ChatInfoView.noInfo
  chatPaneView: ChatPaneView = ChatPaneView.noChat
  chatListView: ChatListView = ChatListView.skeleton
  currentUserId: string
  syncResp: SyncRes
  roomStateResp: RoomStateRes
  storedUsers: Table[cstring, User]
  selectedRoom: string

proc setTimeoutAsync(ms: int): Future[void] =
  let promise = newPromise() do (res: proc(): void):
    discard setTimeout(res, ms)
  return promise

proc longSync {.async.} =
  try:
    syncResp = await client.sync(since = syncResp.nextBatch)
    await setTimeoutAsync(1000)
      .then(longSync)
  except MatrixError:
    await setTimeoutAsync(1000)
      .then(longSync)

proc initialSync {.async.} =
  globalMenuView = MenuView.syncing
  redraw()
  syncResp = await client.sync()
  globalClientView = ClientView.chat
  redraw()
  # discard longSync()

proc login =
  proc loginMatrix(homeserver, username, password: string) {.async.} =
    client = newAsyncMatrixClient(homeserver)
    let loginRes: LoginRes = await client.login(username, password)
    currentUserId = loginRes.userId
    client.setToken loginRes.accessToken
    discard initialSync()
    discard db.storeToken(currentUserId, homeserver, loginRes.accessToken, dbOptions)

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
    discard db.storeToken(currentUserId, homeserver, regRes.accessToken, dbOptions)

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
  client = newAsyncMatrixClient(homeserver, token)
  try:
    let whoAmIResp = await client.whoAmI()
    currentUserId = whoAmIResp.userId
    discard initialSync()
  except MatrixError:
    echo "bad token!"

proc getUsers {.async.} =
  let objStore = await getAll(db, "user".cstring, dbOptions)
  storedUsers = collect:
    for user in to(objStore, seq[User]): {user.userId: user}
  redraw()

proc renderMenu*: Vnode =
  if storedUsers.len == 0:
    discard getUsers()
  result = buildHtml:
    tdiv(class = "modal"):
      for userId, user in storedUsers.pairs:
        button(id = kstring(userId), class = "signed-in-user"):
          text userId
          proc onclick(ev: kdom.Event; n: VNode) =
            let user = storedUsers[n.id]
            discard validate($user.homeserver, $user.token)

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

proc getMatrixRoomState(roomId: string) {.async.} =
  let res = await client.getRoomState(roomId)
  roomStateResp = res
  chatInfoView = ChatInfoView.loaded
  redraw()

proc chatInfo*(roomId: string = ""): Vnode =
  if roomId == "":
    chatInfoView = ChatInfoView.noInfo
  else:
    if roomStateResp == RoomStateRes() or roomStateResp.roomId != selectedRoom:
      chatInfoView = ChatInfoView.loading
      discard getMatrixRoomState(roomId)
  result = buildHtml:
    tdiv(id = "info-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chat Information"
      case chatInfoView:
      of ChatInfoView.noInfo:
        renderNoneSelected()
      of ChatInfoView.loading:
        renderLoader("Loading...")
      of ChatInfoView.loaded:
        renderRoomState(roomStateResp.events)

proc onChatClick(ev: kdom.Event; n: VNode) =
  selectedRoom = $n.id
  chatPaneView = ChatPaneView.selected
  redraw()

proc renderJoinedRooms(joinedRooms: Table[string, JoinedRoom]): Vnode =
  # TODO: Add code to detect whether there is an active overflow and set the last-chat class
  result = buildHtml:
    tdiv(id = "chats", class = "list"):
      for i, (id, room) in enumerate joinedRooms.pairs:
        if i == joinedRooms.len - 1:
          button(class = "chat last-chat", id = kstring(id), onclick = onChatClick):
            text id
        else:
          button(class = "chat", id = kstring(id), onclick = onChatClick):
            text id

proc send(ev: kdom.Event; n: VNode) =
  proc matrixSend(message: string) {.async.} =
    discard await client.sendMessage(eventType = "m.room.message", roomId = selectedRoom, txnId = $getTime(), body = message, msgtype = MessageType.`m.text`)
  let message = $getElementById("message-input").textContent
  getElementById("message-input").textContent = ""
  discard matrixSend(message)

proc chatPane*(userId: string, roomId: string): Vnode =
  result = buildHtml:
    tdiv(id = "chat-pane", class = "col"):
      case chatPaneView:
      of ChatPaneView.noChat:
        renderNoneSelected()
      of ChatPaneView.selected:
        let joinedRoom = syncResp.rooms.join[roomId]
        renderChatMessages(userId, joinedRoom)
      tdiv(id = "message-box", class = "border-box"):
        tdiv(id = "message-input", autofocus = "autofocus", contenteditable = "true", onkeyupenter = send)
        button(id = "send-button", onclick = send):
          text "➤"

proc chatList*(syncResp: SyncRes): Vnode =
  result = buildHtml:
    tdiv(id = "list-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chats"
      case chatListView:
      of ChatListView.skeleton:
        renderJoinedRooms(syncResp.rooms.join)
      of ChatListView.full:
        # TODO: properly render rooms with real names
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
          chatPane(currentUserId, selectedRoom)
          chatInfo(selectedRoom)
      footerSection()

setRenderer createDom
