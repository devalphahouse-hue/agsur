{{flutter_js}}
{{flutter_build_config}}

// Cache-bust do main.dart.js.
// O Flutter web NÃO coloca hash no nome do main.dart.js, então um browser
// que cacheou a versão antiga com `Cache-Control: immutable` (header que
// estava no vercel.json até 2026-05-20) nunca mais refetcha. Mudar o
// caminho com ?v=<commitSha> dá uma URL diferente entre deploys, o browser
// não acha no cache, e baixa a versão fresca. O placeholder
// __AGSUR_BUILD_ID__ é substituído pelo git short-sha no post-build
// (workflow `deploy-vercel.yml`); se a substituição não rodar, cai num
// fallback baseado em Date.now() — pior pra cache, mas nunca quebrado.
(function () {
  var BUILD_ID = "__AGSUR_BUILD_ID__";
  if (BUILD_ID === ("__" + "AGSUR_BUILD_ID__")) {
    // Build local sem substituição — usa timestamp para garantir freshness.
    BUILD_ID = "dev-" + Date.now();
  }
  if (_flutter && _flutter.buildConfig && _flutter.buildConfig.builds) {
    for (var i = 0; i < _flutter.buildConfig.builds.length; i++) {
      var b = _flutter.buildConfig.builds[i];
      if (b && b.mainJsPath && b.mainJsPath.indexOf("?") === -1) {
        b.mainJsPath = b.mainJsPath + "?v=" + BUILD_ID;
      }
    }
  }
})();

_flutter.loader.load(
    {
        onEntrypointLoaded: async function(engineInitializer) {
            // Initialize the Flutter engine
            let appRunner = await engineInitializer.initializeEngine({useColorEmoji: true,});
            // Run the app
            await appRunner.runApp();
          }
    }
);
