setup:
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs

dev:
	flutter run -d macos

build-macos:
	flutter build macos --release

build-ios:
	flutter build ios --release

build-android:
	flutter build apk --release

test:
	flutter test

.PHONY: setup dev build-macos build-ios build-android test
