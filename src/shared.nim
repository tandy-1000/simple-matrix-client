import pkg/karax/[karaxdsl, vdom]

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
