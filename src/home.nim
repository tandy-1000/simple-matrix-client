import
  pkg/karax/[karax, karaxdsl, vdom],
  pkg/matrix,
  shared

proc signinModal: Vnode =
  var loginDiv = buildHtml(tdiv())

  result = buildHtml:
    tdiv(class = "modal"):
      button(id = "login", class = "text-button"):
        text "Sign-in"
        proc onclick() =
          loginDiv = buildHtml(tdiv):
            h3:
              text "Login:"
            input(id = "login-input", `type` = "text")
            input(id = "login-input", `type` = "password")
      p:
        text "or"
      button(id = "register", class = "text-button", ):
        text "Register as Guest"
      loginDiv
      # elif guest:

proc createDom: VNode =
  result = buildHtml:
    tdiv:
      headerSection()
      main:
        signinModal()
      footerSection()

setRenderer createDom
