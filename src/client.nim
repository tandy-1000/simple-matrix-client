import
  pkg/karax/[karax, karaxdsl, vdom, kdom],
  pkg/matrix,
  shared

type
  ClientView = enum
    signinView, chatView
  MenuView* = enum
    menuView, loginView, registerView

var
  globalClientView = ClientView.signinView
  globalMenuView = MenuView.menuView
  client = newMatrixClient("")
  chats: seq[string]
  chatParticipants: seq[string]
  chatName: string
  messages: seq[string]
# chats = @["Chat Group 1", "Chat Group 2"]
# chatParticipants = @["user1", "user2", "user3"]
# chatName = "chat"
# messages = @["hello!", "hello."]

proc loginMatrix(homeserver, username, password: string) =
  client = newMatrixClient(homeserver)
  let loginRes = client.login(username, password)
  client.setToken loginRes.accessToken

proc login =
  let
    homeserver = $getElementById("homeserver").value
    username = $getElementById("username").value
    password = $getElementById("password").value
  globalClientView = ClientView.chatView
  loginMatrix(homeserver, username, password)

proc registerMatrix(homeserver, password: string) =
  client = newMatrixClient(homeserver)
  let regRes = client.registerGuest(password)
  # client.setToken regRes.accessToken

proc register =
  let
    homeserver = $getElementById("homeserver").value
    password = $getElementById("password").value
  globalClientView = ClientView.chatView
  registerMatrix(homeserver, password)

proc signinModal*: Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      case globalMenuView:
      of MenuView.menuView:
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
        input(id = "homeserver", class = "login-input", `type` = "text", onkeyupenter = login, placeholder = "https://homeserver.org")
        input(id = "username", class = "login-input", `type` = "text", onkeyupenter = login, placeholder = "username")
        input(id = "password", class = "login-input", `type` = "password", onkeyupenter = login, placeholder = "password")
        button(id = "login", class = "text-button", onclick = login):
          text "Login"
      of MenuView.registerView:
        h3:
          text "Register as guest:"
        input(id = "homeserver", class = "login-input", `type` = "text", onkeyupenter = register, placeholder = "https://homeserver.org")
        input(id = "password", class = "login-input", `type` = "password", onkeyupenter = register, placeholder = "password")
        button(id = "register", class = "text-button", onclick = register):
          text "Register"

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
      of ClientView.signinView:
        main:
          signinModal()
      of ClientView.chatView:
        main:
          chatList()
          chatPane()
          chatInfo()
      footerSection()

setRenderer createDom
