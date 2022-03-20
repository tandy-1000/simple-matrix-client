import
  pkg/karax/[karax, kbase, karaxdsl, vdom, kdom],
  pkg/matrix,
  pkg/nodejs/jsindexeddb,
  std/[asyncjs, tables, json, jsffi, enumerate, times, options],
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
  currentUserId, selectedRoom: string
  initSyncResp, syncResp: SyncRes
  roomStateResp: RoomStateRes
  roomMessagesResp: RoomMessagesRes
  storedUsers: Table[cstring, User]

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
  initSyncResp = await client.sync()
  syncResp = initSyncResp
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

proc renderLogin*: Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      h3(class = "modal-header"):
        text "Login:"
      input(id = "homeserver", class = "login-input", `type` = "text", onkeyupenter = login, value = "https://matrix.org", placeholder = "https://homeserver.org")
      input(id = "username", class = "login-input", `type` = "text", onkeyupenter = login, placeholder = "username")
      input(id = "password", class = "login-input", `type` = "password", onkeyupenter = login, placeholder = "password")
      button(id = "login", class = "text-button", onclick = login):
        text "Login"

proc register =
  proc registerMatrix(homeserver, alias: string, deviceId = dbName) {.async.} =
    client = newAsyncMatrixClient(homeserver)
    let regRes: RegisterRes = await client.registerGuest(deviceId = deviceId)
    currentUserId = regRes.userId
    client.setToken regRes.accessToken
    let displaynameRes = await client.setDisplayname(regRes.userId, alias)
    discard initialSync()
    discard db.storeToken(currentUserId, homeserver, regRes.accessToken, dbOptions)

  let
    homeserver = $getElementById("homeserver").value
    alias = $getElementById("alias").value

  discard registerMatrix(homeserver, alias)

proc renderRegister*: Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      h3(class = "modal-header"):
        text "Register as guest:"
      input(id = "homeserver", class = "login-input", `type` = "text", onkeyupenter = register, value = "https://matrix.org", placeholder = "https://homeserver.org")
      input(id = "alias", class = "login-input", `type` = "text", onkeyupenter = register, placeholder = "What should we call you?")
      button(id = "register", class = "text-button", onclick = register):
        text "Register"

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
        # renderNoneSelected()
        echo "no info!"
      of ChatInfoView.loading:
        renderLoader("Loading...")
      of ChatInfoView.loaded:
        renderRoomState(roomStateResp.events)

proc getMessages(roomId, prevBatch: string) {.async.} =
  roomMessagesResp = await client.getRoomMessages(roomId, `from` = prevBatch, dir = Direction.backward)
  redraw()

proc onChatClick(ev: kdom.Event; n: VNode) =
  selectedRoom = $n.id
  chatPaneView = ChatPaneView.selected
  discard getMessages(selectedRoom, initSyncResp.rooms.join[selectedRoom].timeline.prevBatch)
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

proc scrollMessages(ev: kdom.Event; n: VNode) =
  let outerDom = n.dom
  if outerDom != nil and (outerDom.scrollHeight - outerDom.offsetHeight) == -outerDom.scrollTop:
    if selectedRoom != "" and roomMessagesResp.`end`.isSome():
      discard getMessages(selectedRoom, roomMessagesResp.`end`.get())

proc renderChatMessages*(userId: string, events: seq[ClientEventWithoutRoomID]): Vnode =
  var body: string
  let messageClass = "message"
  result = buildHtml:
    tdiv(id = "messages", onscroll = scrollMessages):
      tdiv(id = "inner-messages"):
        for event in events:
          if event.`type` == "m.room.message":
            body = event.content{"formatted_body"}.getStr()
            if body == "":
              body = event.content{"body"}.getStr()
            renderMessage(userId, event.eventId, messageClass, event.sender, body)
          elif event.`type` == "m.room.encrypted":
            renderMessage(userId, event.eventId, messageClass, event.sender, "`Encrypted message`")

proc renderChatMessages*(userId: string, events: seq[ClientEvent]): Vnode =
  var body: string
  let messageClass = "message"
  result = buildHtml:
    tdiv(id = "messages", onscroll = scrollMessages):
      tdiv(id = "inner-messages"):
        for event in events:
          if event.`type` == "m.room.message":
            body = event.content{"formatted_body"}.getStr()
            if body == "":
              body = event.content{"body"}.getStr()
            renderMessage(userId, event.eventId, messageClass, event.sender, body)
          elif event.`type` == "m.room.encrypted":
            renderMessage(userId, event.eventId, messageClass, event.sender, "`Encrypted message`")

proc chatPane*(userId: string, roomId: string): Vnode =
  result = buildHtml:
    tdiv(id = "chat-pane", class = "col"):
      if roomId != "":
        h3(id = "chat-header"):
            text roomId
      case chatPaneView:
      of ChatPaneView.noChat:
        renderNoneSelected()
      of ChatPaneView.selected:
        let events = initSyncResp.rooms.join[roomId].timeline.events
        # let events = roomMessagesResp.chunk
        renderChatMessages(userId, events)
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

proc matrixClient(renderChatList, renderChatInfo = true)*: Vnode =
  result = buildHtml:
    tdiv(id = "matrix-client"):
      case globalClientView:
      of ClientView.signin:
        signinModal()
      of ClientView.chat:
        if renderChatList:
          chatList(initSyncResp)
        chatPane(currentUserId, selectedRoom)
        if renderChatInfo:
          chatInfo(selectedRoom)
