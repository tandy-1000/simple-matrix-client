import
  pkg/karax/[karax, karaxdsl, vdom, kdom],
  pkg/matrix,
  std/asyncjs,
  shared
from std/sugar import `=>`

var
  chats: seq[string]
  chatParticipants: seq[string]
  chatName: string
  messages: seq[string]

type
  ClientView = enum
    signin = "signin",
    chat = "chat"
  MenuView* = enum
    menu = "menu",
    loginView = "login",
    registerView = "register",
    syncing = "syncing"

var
  globalClientView = ClientView.signin
  globalMenuView = MenuView.menu
  client = newAsyncMatrixClient("")
  syncResp: SyncRes

proc setSyncView(res: Syncres) =
  syncResp = res
  globalClientView = ClientView.chat
  redraw()

proc initialSync {.async.} =
  globalMenuView = MenuView.syncing
  redraw()
  await client.sync()
    .then((syncResp: SyncRes) => setSyncView syncResp)

proc login =
  proc loginMatrix(homeserver, username, password: string) {.async.} =
    client = newAsyncMatrixClient(homeserver)
    await client.login(username, password)
      .then((loginRes: LoginRes) => client.setToken loginRes.accessToken)
      .then(initialSync)

  let
    homeserver = $getElementById("homeserver").value
    username = $getElementById("username").value
    password = $getElementById("password").value
  discard loginMatrix(homeserver, username, password)

proc register =
  proc registerMatrix(homeserver, password: string) {.async.} =
    client = newAsyncMatrixClient(homeserver)
    await client.registerGuest(password)
      .then((regRes: RegisterRes) => client.setToken regRes.accessToken)
      .then(initialSync)

  let
    homeserver = $getElementById("homeserver").value
    password = $getElementById("password").value
  discard registerMatrix(homeserver, password)

proc signinModal*: Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      case globalMenuView:
      of MenuView.menu:
        button(id = "signin", class = "text-button"):
          text "Sign-in"
          proc onclick() = globalMenuView = MenuView.loginView
        p:
          text "or"
        button(id = "register", class = "text-button"):
          text "Register as Guest"
          proc onclick() = globalMenuView = MenuView.registerView
      of MenuView.loginView:
        h3:
          text "Login:"
        input(id = "homeserver", class = "login-input", `type` = "text", onkeyupenter = login, value = "https://matrix.org", placeholder = "https://homeserver.org")
        input(id = "username", class = "login-input", `type` = "text", onkeyupenter = login, placeholder = "username")
        input(id = "password", class = "login-input", `type` = "password", onkeyupenter = login, placeholder = "password")
        button(id = "login", class = "text-button", onclick = login):
          text "Login"
      of MenuView.registerView:
        h3:
          text "Register as guest:"
        input(id = "homeserver", class = "login-input", `type` = "text", onkeyupenter = register, value = "https://matrix.org", placeholder = "https://homeserver.org")
        input(id = "password", class = "login-input", `type` = "password", onkeyupenter = register, placeholder = "password")
        button(id = "register", class = "text-button", onclick = register):
          text "Register"
      of MenuView.syncing:
        h3:
          text "Initial sync..."
        img(id = "spinner", src = "/public/assets/spinner.svg")

proc chatList: Vnode =
  result = buildHtml:
    tdiv(id = "list-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chats"
      tdiv(id = "chats", class = "list"):
        for chat in chats:
          tdiv(id = "chat"):
            p:
              text chat

proc chatPane: Vnode =
  result = buildHtml:
    tdiv(id = "chat-pane", class = "col"):
      tdiv(id = "messages"):
        for message in messages:
          p(id = "message"):
            text message
      tdiv(id = "message-box", class = "border-box"):
        input(id = "message-input", `type` = "text")
        button(id = "send-button"):
          text "➤"

proc chatInfo: Vnode =
  result = buildHtml:
    tdiv(id = "info-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chat Information"
      if chatParticipants.len != 0:
        tdiv(id = "chat-information"):
          tdiv(id = "chat-profile"):
            h4(id = "chat-name"):
              text chatName
          tdiv(id = "members"):
            p(class = "heading"):
              text "Members:"
            tdiv(class = "list"):
              for chatParticipant in chatParticipants:
                tdiv(id = "chat-participant"):
                  p:
                    text chatParticipant

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
          chatList()
          chatPane()
          chatInfo()
      footerSection()

setRenderer createDom
