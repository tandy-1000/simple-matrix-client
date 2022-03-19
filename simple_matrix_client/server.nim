when not defined(js):
  import
    pkg/prologue,
    pkg/prologue/middlewares/[staticfile, cors],
    urls

  let
    env = loadPrologueEnv(".env")
    settings = newSettings(
      appName = env.getOrDefault("appName", "Simple Matrix Client"),
      debug = env.getOrDefault("debug", true),
      port = Port(env.getOrDefault("port", 8080))
    )

  var app = newApp(settings = settings)

  app.use(staticFileMiddleware(env.get("staticDir")))
  app.use(CorsMiddleware(allowOrigins = @[env.getOrDefault("allowOrigins", "*")],
    allowMethods = @[env.getOrDefault("allowMethods", "*")]))
  app.addRoute(urls.urlPatterns, "")
  app.run()
