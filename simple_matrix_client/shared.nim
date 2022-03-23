import
  pkg/karax/[kbase, karaxdsl, vdom],
  pkg/matrix,
  pkg/nodejs/jsindexeddb,
  std/[asyncjs, json, jsffi, dom],
  types

proc setTimeoutAsync*(ms: int): Future[void] =
  let promise = newPromise() do (res: proc(): void):
    discard setTimeout(res, ms)
  return promise

proc storeToken*(db: IndexedDB, userId, homeserver, token: string = "", options: IDBOptions) {.async.} =
  discard await put(db, "user".cstring, toJs User(userId: userId.cstring, homeserver: homeserver.cstring, token: token.cstring), options)

proc renderRoomMembers*(members: seq[ClientEvent]): Vnode =
  result = buildHtml:
    tdiv(id = "members"):
      p(class = "heading"):
        text "Members:"
      tdiv(class = "list"):
        for member in members:
          p(id = "chat-participant"):
            text member.content{"displayname"}.getStr()

proc renderRoomState*(events: seq[ClientEvent]): Vnode =
  var
    chatName: string
    members: seq[ClientEvent]

  if events.len != 0:
    for clientEv in events:
      if clientEv.`type` == "m.room.member":
        members &= clientEv
      elif clientEv.`type` == "m.room.name":
        chatName = clientEv.content{"name"}.getStr()

  result = buildHtml:
    tdiv(id = "chat-information"):
      tdiv(id = "chat-profile"):
        h4(id = "chat-name"):
          text chatName
      renderRoomMembers(members)

proc renderMessage*(userId, eventId, messageClass, sender, body: string): Vnode =
  var class = messageClass
  if sender == userId:
    class &= " self-sent"
  result = buildHtml:
    tdiv(id = kstring(eventId), class = kstring(class)):
      p(class = "message-sender"):
        text sender
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
