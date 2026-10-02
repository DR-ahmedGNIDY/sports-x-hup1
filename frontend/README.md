# Sport X Hub — App

This folder is the app. It is the only source for both:

- the **Android build** published on Google Play (`com.sportxhub.sport_x_hub`)
- the **web build** served on `app.sportxhup.com`

The public website on `sportxhup.com` lives in `../website/` and is a separate
project. Website work must not modify anything in this folder.

## Rules for changing this folder

- Each change here is its own commit, made on purpose. A website task is never
  a reason to edit a file in `frontend/`.
- Every Google Play upload needs a higher build number than the last one:
  bump `version:` in `pubspec.yaml` (the `+N` part is the Play `versionCode`).
- Release signing reads `android/key.properties` and
  `android/app/upload-keystore.jks`. Both are git-ignored and must never be
  committed. Losing them means losing the ability to update the Play listing.

## Building

```bash
flutter build appbundle --release   # Google Play
flutter build web --release         # app.sportxhup.com
```

Production builds use the production `.env`; see `../DEPLOY.md`.
