# GitHub Secrets to Create

To use this workflow, you need to create the following GitHub secrets in your repository:

- **ANDROID_KEYSTORE_BASE64**: Base64-encoded contents of your Android keystore file (.jks).

  - Generate a keystore file if you haven't already.
  - Encode the keystore file to base64.
  - Copy the content of `android_keystore.jks.base64` and set it as the `ANDROID_KEYSTORE_BASE64` secret.

- **KEYSTORE_PASSWORD**: The password you set when creating the keystore.

  - Use the password set during the keystore generation.

- **KEY_PASSWORD**: The password for the key alias (often the same as the keystore password).

  - Use the alias password set during keystore generation.

- **KEY_ALIAS**: The alias name you used when creating the key.

  - The alias specified with `-alias your-key-alias`.

- **FIREBASE_ANDROID_APP_ID**: Your Firebase Android App ID.

  - Find this in the Firebase console under Project Settings > General.

- **FIREBASE_TOKEN**: Firebase CI token for authentication.
  - Generate a token by running:
  - Set the generated token as the `FIREBASE_TOKEN` secret.

Add these secrets by navigating to your repository's **Settings > Secrets and variables > Actions > New repository secret**.

## Additional Configuration

### Update build.gradle for Signing Configuration

Modify your `android/app/build.gradle` file to use the keystore and signing configurations.

### Ensure Keystore is Ignored

Add `key.jks` to your `.gitignore` file to prevent it from being committed.

### Set Up Firebase App

Ensure that your Android app is registered in your Firebase project:

1. Go to the Firebase Console and select your project.
2. Add a new Android app with your application's package name (e.g., `com.example.app`).
3. Download the `google-services.json` file and place it in `android/app/`.

### Update FlutterFire Configuration

If you're using FlutterFire, configure it for Android.
