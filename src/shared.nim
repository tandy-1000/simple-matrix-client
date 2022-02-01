import
  pkg/karax/[kbase, karaxdsl, vdom],
  pkg/matrix,
  std/[tables, enumerate, json]

type
  ClientView* = enum
    signin = "signin",
    chat = "chat"
  MenuView* = enum
    menu = "menu",
    loginView = "login",
    registerView = "register",
    syncing = "syncing"

proc renderJoinedRooms(joinedRooms: Table[string, JoinedRoom]): Vnode =
  # TODO: Add code to detect whether there is an active overflow and set the last-chat class
  result = buildHtml:
    tdiv(id = "chats", class = "list"):
      for i, (id, room) in enumerate joinedRooms.pairs:
        if i == joinedRooms.len - 1:
          tdiv(class = "last-chat", id = kstring(id)):
            p:
              text id
        else:
          tdiv(class = "chat", id = kstring(id)):
            p:
              text id

proc chatList*(syncResp: SyncRes): Vnode =
  result = buildHtml:
    tdiv(id = "list-pane", class = "col"):
      h3(id = "chat-header"):
        text "Chats"
      renderJoinedRooms(syncResp.rooms.join)

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
            body = content["body"].getStr()
          if event.sender == userId:
            messageClass &= " self-sent"
            echo messageClass
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

proc chatInfo*(chatParticipants: seq[string] = @[], chatName: string = ""): Vnode =
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
