import
  pkg/karax/[kbase, karaxdsl, vdom],
  pkg/matrix,
  pkg/nodejs/jsindexeddb,
  std/[asyncjs, json, jsffi]

type
  ClientView* = enum
    signin = "signin",
    chat = "chat"
  MenuView* = enum
    menu = "menu",
    loginView = "login",
    registerView = "register",
    syncing = "syncing"
  ChatListView* = enum
    skeleton = "skeleton",
    full = "full"
  ChatPaneView* = enum
    noChat = "none",
    selected = "selected"
  ChatInfoView* = enum
    noInfo = "noInfo",
    loading = "loading",
    loaded = "loaded"

  User* = object
    userId*: cstring
    homeserver*: cstring
    token*: cstring

proc storeToken*(db: IndexedDB, userId, homeserver, token: string = "", options: IDBOptions) {.async.} =
  discard await put(db, "user".cstring, toJs User(userId: userId.cstring, homeserver: homeserver.cstring, token: token.cstring), options)

proc renderRoomMembers*(members: seq[StateEvent]): Vnode =
  result = buildHtml:
    tdiv(id = "members"):
      p(class = "heading"):
        text "Members:"
      tdiv(class = "list"):
        for member in members:
          p(id = "chat-participant"):
            text member.content{"displayname"}.getStr()

proc renderRoomState*(events: seq[StateEvent]): Vnode =
  var
    chatName: string
    members: seq[StateEvent]

  if events.len != 0:
    for stateEv in events:
      if stateEv.`type` == "m.room.member":
        members &= stateEv
      elif stateEv.`type` == "m.room.name":
        chatName = stateEv.content{"name"}.getStr()

  result = buildHtml:
    tdiv(id = "chat-information"):
      tdiv(id = "chat-profile"):
        h4(id = "chat-name"):
          text chatName
      renderRoomMembers(members)

proc renderChatMessages*(userId: string, joinedRoom: JoinedRoom): Vnode =
  var
    body: string
    messageClass: string
  result = buildHtml:
    tdiv(id = "messages"):
      tdiv(id = "inner-messages"):
        for event in joinedRoom.timeline.events:
          if event.`type` == "m.room.message":
            messageClass = "message"
            body = event.content{"formatted_body"}.getStr()
            if body == "":
              body = event.content{"body"}.getStr()
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

proc renderNoneSelected*: Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      h3:
        text "No chat selected."

proc renderLoader*(message: string): Vnode =
  result = buildHtml:
    tdiv(class = "modal"):
      h3(class = "modal-header"):
        text message
      img(id = "spinner", src = "/simple-matrix-client/assets/spinner.svg")

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
