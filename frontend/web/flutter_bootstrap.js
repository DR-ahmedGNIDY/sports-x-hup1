// Custom Flutter Web bootstrap. Identical to the file Flutter generates by
// default, plus one addition: it dismisses the boot screen declared in
// web/index.html once the app has actually rendered, instead of leaving a
// blank canvas visible while main.dart.js is fetched, parsed and started.
//
// The `{{...}}` tokens are substituted by `flutter build web` / `flutter run`
// — do not hand-expand them.

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
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
