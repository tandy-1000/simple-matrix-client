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
