import
  pkg/prologue,
  views

const urlPatterns* = @[
  pattern("/", home),
  pattern("/client", client),
]
