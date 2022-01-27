import
  pkg/karax/[karax, karaxdsl, vdom],
  pkg/matrix,
  shared

# proc onMessageEnter(ev: Event; n: VNode) =
#   echo "send message:" & $getElementById("message_input").value

var
  chats: seq[string]
  chatParticipants: seq[string]
  chatName: string
  messages: seq[string]

# chats = @["Chat Group 1", "Chat Group 2"]
# chatParticipants = @["user1", "user2", "user3"]
# chatName = "chat"
# messages = @["hello!", "hello."]

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
      script(`type` = "text/javascript", src="/public/client.js")
      headerSection()
      main:
        chatList()
        chatPane()
        chatInfo()
      footerSection()

setRenderer createDom
