import
  pkg/karax/[karax, karaxdsl, vdom],
  pkg/matrix,
  shared

proc createDom: VNode =
  result = buildHtml:
    tdiv:
      headerSection()
      main()
      footerSection()

setRenderer createDom
