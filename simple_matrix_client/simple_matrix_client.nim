import
  pkg/karax/[karax, karaxdsl, vdom],
  client, shared

proc createDom*: VNode =
  result = buildHtml:
    tdiv:
      headerSection()
      main:
        matrixClient()
      footerSection()

setRenderer(createDom, root = cstring "global")
