import
  pkg/karax/[karax, karaxdsl, vdom],
  client, shared

proc createDom*: VNode =
  result = buildHtml:
    tdiv:
      headerSection()
      matrixClient()
      footerSection()

setRenderer createDom
