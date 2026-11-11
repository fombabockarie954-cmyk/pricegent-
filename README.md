# Pricegent

Pricegent is an interactive AI learning app that helps learners practice the
S.E.E. principle. It is built with Flutter/Dart and a
separate Python/FastAPI service. The API is designed to run as a hosted service,
so study generation does not depend on a developer's laptop being online. Its
first study flow accepts pasted material and turns it into:

- Key concepts and definitions with exact excerpts from the supplied source.
- The learner's S.E.E. learning method: **Sense**, **Exaggerate**, **Energize**.
- An interactive concept map with labeled relationships.
- Active-recall questions with answers revealed on demand.

The Exaggerate step is explicitly a thought experiment: the guide shows what
stays true and where the imagined model stops matching reality.

## Deploy the API

The repository includes a Render Blueprint in [render.yaml](render.yaml). It
uses Render's free instance plan, which can sleep after inactivity and cold-start
on the next request. Create a Render service from this repository using that
Blueprint, then configure the model provider environment variables in the
Render dashboard:

- `PRICEGENT_LLM_API_KEY`
- `PRICEGENT_LLM_MODEL`
- `PRICEGENT_LLM_BASE_URL` (optional; defaults to OpenAI's API URL)
- `PRICEGENT_IMAGE_API_KEY` (optional; needed for image generation unless the
  model API key is also a Gemini key)
- `FIREBASE_SERVICE_ACCOUNT_JSON` (required; Firebase Admin service-account JSON)

Keep all provider keys and the Firebase service-account JSON in Render's
environment settings; never put them in the Flutter app, paste them into chat,
or commit them. After deployment, check the service's `/health` endpoint and
copy its HTTPS service URL.

The study and illustration endpoints require a Firebase ID token from a user
signed in with Google. The health check is intentionally public.

## Configure Firebase sign-in

The Firebase Android app and Google sign-in provider must be configured for
package name `com.pricegent.pricegent_mobile`. Add the Android SHA fingerprints
from `.\gradlew signingReport` (run from `android`) to the Firebase app. Firebase
client identifiers are set in [firebase_config.dart](lib/firebase_config.dart);
they are public app configuration, not secrets. The backend service-account
private key is secret.

Create a Firebase service-account key in Firebase project settings and add its
full JSON contents to Render as `FIREBASE_SERVICE_ACCOUNT_JSON`. Never commit
that JSON or share it in chat.

Build the Android app with the deployed API URL:

```powershell
flutter run --dart-define=PRICEGENT_API_BASE_URL=https://your-service.onrender.com
```

## Run the mobile app

Set the hosted HTTPS service URL for every build:

```powershell
flutter pub get
flutter run --dart-define=PRICEGENT_API_BASE_URL=https://your-service.onrender.com
```

Replace the example URL with your Render service URL (no trailing slash).
Android emulators and physical phones use the same hosted URL. The app has no
laptop-hosted default; if the URL is omitted, study generation reports a
configuration error. Firebase app settings are required to sign in and use the
study endpoints.

## Run the API

See [backend/README.md](backend/README.md) for local development and hosted
deployment details. Model credentials stay on the backend and are never
embedded in the mobile app.

The API intentionally reports a configuration error until its model is
configured. The app only sends study material to the service after the learner
chooses **Build my study guide**. Study data is currently held in memory and is
not yet persisted between app launches.

## Verify

```powershell
flutter analyze
flutter test
python -m pytest
```
