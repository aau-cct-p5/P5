GitHub Secrets to Create

# GitHub Actions Workflow Secrets

To use this workflow, you need to create the following GitHub secrets in your repository:

### APPSTORE_CERT_BASE64

- **Description**: Base64-encoded contents of your Apple distribution certificate (.p12 file).
- **Steps**:
  1. Export your certificate from Keychain Access as a .p12 file.
  2. Encode the certificate file to base64:
     ```sh
     openssl base64 -in Certificate.p12 -out Certificate.p12.base64
     ```
  3. Copy the contents of `Certificate.p12.base64` and set it as the `APPSTORE_CERT_BASE64` secret.

### APPSTORE_CERT_PASSWORD

- **Description**: The password you set when exporting the .p12 certificate.
- **Steps**:
  1. Use the password you created during the export process.
  2. Set it as the `APPSTORE_CERT_PASSWORD` secret.

### MOBILEPROVISION_BASE64

- **Description**: Base64-encoded contents of your provisioning profile (.mobileprovision file).
- **Steps**:
  1. Download your provisioning profile from the Apple Developer portal.
  2. Encode the provisioning profile to base64:
     ```sh
     openssl base64 -in ProvisioningProfile.mobileprovision -out ProvisioningProfile.mobileprovision.base64
     ```
  3. Copy the contents of `ProvisioningProfile.mobileprovision.base64` and set it as the `MOBILEPROVISION_BASE64` secret.

### KEYCHAIN_PASSWORD

- **Description**: A secure password for the temporary keychain.
- **Steps**:
  1. Generate a random password.
  2. Set it as the `KEYCHAIN_PASSWORD` secret.

### FIREBASE_IOS_APP_ID

- **Description**: Your Firebase iOS App ID.
- **Steps**:
  1. Find this in the Firebase console under Project Settings -> General.
  2. Set it as the `FIREBASE_IOS_APP_ID` secret.

### FIREBASE_TOKEN

- **Description**: Firebase CI token for authentication.
- **Steps**:
  1. Generate a token by running:
     ```sh
     firebase login:ci
     ```
  2. Set the generated token as the `FIREBASE_TOKEN` secret.

### Adding Secrets

Add these secrets by navigating to your repository's **Settings** > **Secrets and variables** > **Actions** > **New repository secret**.
