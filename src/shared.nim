import
  pkg/karax/[kbase, karaxdsl, vdom],
  pkg/matrix,
  std/json

type
  ClientView* = enum
    signin = "signin",
    chat = "chat"
  MenuView* = enum
    menu = "menu",
    loginView = "login",
    registerView = "register",
    syncing = "syncing"
  InfoView* = enum
    none = "none",
    loading = "loading",
    some = "some"

proc renderChatMessages(userId: string, joinedRoom: JoinedRoom): Vnode =
  var
    content: JsonNode
    body: string
    messageClass: string
  result = buildHtml:
    tdiv(id = "messages"):
      tdiv(id = "inner-messages"):
        for event in joinedRoom.timeline.events:
          messageClass = "message"
          content = event.content
          body = content{"formatted_body"}.getStr()
          if body == "":
            body = content{"body"}.getStr()
          if event.sender == userId:
            messageClass &= " self-sent"
          tdiv(id = kstring(event.eventId), class = kstring(messageClass)):
            p(class = "message-sender"):
              text event.sender
            p(class = "message-body"):
              if body == "":
                text body
              else:
                verbatim body

proc chatPane*(userId: string, joinedRoom: JoinedRoom): Vnode =
  result = buildHtml:
    tdiv(id = "chat-pane", class = "col"):
      renderChatMessages(userId, joinedRoom)
      tdiv(id = "message-box", class = "border-box"):
        input(id = "message-input", `type` = "text")
        button(id = "send-button"):
          text "➤"

proc headerSection*: Vnode =
  result = buildHtml:
    header:
      h2:
        a(href = "/"):
          text "Simple Matrix Client"

proc footerSection*: Vnode =
  result = buildHtml:
    footer:
      h4:
        text "Made with ♥ in Nim."
