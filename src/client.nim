import
  matrix,
  pkg/karax/[karax, karaxdsl, vdom]

# proc onMessageEnter(ev: Event; n: VNode) =
#   echo "send message:" & $getElementById("message_input").value

var
  chats: seq[string] = @["Chat Group 1", "Chat Group 2"]
  chatParticipants: seq[string] = @["user1", "user2", "user3"]
  chatName: string = "chat"
  messages: seq[string] = @["hello!", "hello."]

proc mainSection(): Vnode =
  result = buildHtml(main()):
    tdiv(id = "list-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chats"
      tdiv(id = "chats", class = "list"):
        for chat in chats:
          tdiv(id = "chat"):
            p():
              text chat
    tdiv(id = "chat-pane", class = "col"):
      tdiv(id = "messages"):
        for message in messages:
          p(id = "message"):
            text message
      tdiv(id = "message-box", class = "border-box"):
        input(id = "message_input", `type` = "text")
        button(id = "send"):
          text "➤"
    tdiv(id = "info-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chat Information"
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
                p():
                  text chatParticipant

proc createDom(): VNode =
  result = buildHtml(tdiv()):
    header():
      h2:
        a(href = "/"):
          text "Simple Matrix Client"
    mainSection()
    footer():
      h4:
        text "Made with ♥ in Nim."

setRenderer createDom
