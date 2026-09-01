// Custom Flutter Web bootstrap. Identical to the file Flutter generates by
// default, plus one addition: it dismisses the boot screen declared in
// web/index.html once the app has actually rendered, instead of leaving a
// blank canvas visible while main.dart.js is fetched, parsed and started.
//
// The `{{...}}` tokens are substituted by `flutter build web` / `flutter run`
// — do not hand-expand them.

{{flutter_js}}
{{flutter_build_config}}

// The app's own service worker, registered here rather than through
// `serviceWorkerSettings`. As of Flutter 3.44 the worker Flutter generates is
// a tombstone that unregisters itself and caches nothing, so letting the
// loader register it would leave the app with no offline story *and* would
// fight the registration below for the same scope.
//
// The build version travels as a query parameter; the worker uses it to name
// its cache, so every deploy gets a fresh one.
// Assigned rather than interpolated into the URL string: the token expands to
// a JS *expression* (a quoted number followed by a block comment), so
// inlining it produces a nonsense path that 404s and registers nothing.
const serviceWorkerVersion = {{flutter_service_worker_version}};

if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker
      .register('sxh_service_worker.js?v=' + serviceWorkerVersion)
      .catch(function (error) {
        // A failed registration costs the offline cache, never the app.
        console.warn('Service worker registration failed:', error);
      });
  });
}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    // `runApp` resolves once the app is running, which is a frame or two
    // before there are actual pixels. Waiting two animation frames lets
    // Flutter paint underneath the still-opaque loader, so the crossfade
    // reveals the app rather than a flash of empty background.
    requestAnimationFrame(() => requestAnimationFrame(dismissLoader));

    // A backgrounded tab never fires `requestAnimationFrame` at all, so the
    // line above alone would strand the boot screen on top of a fully
    // rendered app until the user focused the tab — the common "open link in
    // a new tab" case. This timer does not depend on the compositor.
    setTimeout(dismissLoader, 1200);
  },
});

let loaderDismissed = false;

function dismissLoader() {
  if (loaderDismissed) return;
  loaderDismissed = true;

  const loader = document.getElementById('sxh-loader');
  if (!loader) return;

  loader.classList.add('sxh-loader--done');
  loader.addEventListener('transitionend', () => loader.remove(), { once: true });
  // The fade's `transitionend` never arrives under a reduced-motion setting
  // or in a hidden tab, and the loader must never outlive the boot.
  setTimeout(() => loader.remove(), 1000);
}
