
name: Build Flutter APK

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Setup Project and Dependencies
        run: |
          flutter create --org com.reels.cropper --overwrite .
          flutter pub add image_picker video_player ffmpeg_kit_flutter_min_gpl gallery_saver

      - name: Build Release APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: ReelsCropper-APK
          path: build/app/outputs/flutter-apk/app-release.apk
