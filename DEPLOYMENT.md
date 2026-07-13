# Bedrock Abbottabad Backend Deployment Guide

The backend runs on Firebase: Firestore, Firebase Auth (Email + Google), App Check, FCM, and Cloud Functions (Node.js). **Firebase Storage is not used.**

---

## Prerequisites
Before beginning, make sure you have the following installed on your development machine:
1. [Node.js](https://nodejs.org/) (Version 18 or 20 recommended)
2. [Flutter SDK](https://docs.flutter.dev/get-started/install)
3. [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)

---

## 1. Firebase Project Initialization
1. Log in to Firebase CLI:
   ```bash
   firebase login
   ```
2. Navigate to the project root directory and link the project:
   ```bash
   firebase use bedrock-weather-app
   ```
   *(If the project is not yet created, create it via the [Firebase Console](https://console.firebase.google.com/) and use its ID).*

---

## 2. Deploy Database Security Rules & Indexes
Deploy the Firestore security rules and composite indexes to enforce access control, schema validation, and correct query execution.

1. **Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```
2. **Firestore Indexes** (composite only — single-field indexes are auto-managed by Firestore):
   ```bash
   firebase deploy --only firestore:indexes
   ```

> [!NOTE]
> Firebase Storage is **not** deployed. The Storage SDK in the app is wrapped in a try-catch and will fail silently if Storage is disabled.

---

## 3. Deploy Firebase Cloud Functions

> [!IMPORTANT]
> Cloud Functions **require the Blaze (pay-as-you-go) plan**. This project stays on the **free Spark plan**.
>
> All API calls (Open-Meteo weather, USGS earthquakes, ReliefWeb reports) are made **directly from the Flutter app** via HTTP. No Cloud Functions are deployed.
>
> The `/functions` directory is kept for reference in case you upgrade later.

---

## 4. Enable Google Sign-In
1. Go to **Firebase Console** > **Authentication** > **Sign-in method**.
2. Enable the **Google** provider and save.

---

## 5. Setup App Check (Security Attestation)
To prevent unauthorized API access, register your app with Firebase App Check:
1. Go to the **Firebase Console** > **App Check**.
2. Register your Android app with **Play Integrity** (requires uploading SHA-256 fingerprint).
3. Register your iOS app with **DeviceCheck** (requires uploading Apple Developer team credentials).

---

## 6. Firebase Cloud Messaging (FCM) Configuration
1. **Android:** Enabled via `google-services.json`.
2. **iOS:** Upload your APNs Key (.p8) in **Project Settings** > **Cloud Messaging**.

---

## File Reference:
*   [firestore.rules](file:///e:/antigravity%20playground/Bedrock/firestore.rules): Database access policies.
*   [firestore.indexes.json](file:///e:/antigravity%20playground/Bedrock/firestore.indexes.json): Composite query indexes.
*   [functions/index.js](file:///e:/antigravity%20playground/Bedrock/functions/index.js): Cloud functions logic.
