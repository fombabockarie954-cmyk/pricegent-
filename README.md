# Pricegent

Pricegent is an Android-first learning app built with Flutter/Dart and a
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

The repository includes a Render Blueprint in [render.yaml](render.yaml). Create
a Render service from this repository using that Blueprint, then configure the
model provider environment variables in the Render dashboard:

- `PRICEGENT_LLM_API_KEY`
- `PRICEGENT_LLM_MODEL`
- `PRICEGENT_LLM_BASE_URL` (optional; defaults to OpenAI's API URL)
- `PRICEGENT_IMAGE_API_KEY` (optional; needed for image generation unless the
  model API key is also a Gemini key)

Keep all provider keys in Render's environment settings; never put them in the
Flutter app or commit them. After deployment, check the service's `/health`
endpoint and copy its HTTPS service URL.

**Before deploying a public service with model credentials, add authentication
and rate limiting.** The current API has neither, so anyone who discovers its
URL could use your configured model account and incur charges. The health check
does not protect the study endpoints.

## Run the mobile app

Set the hosted HTTPS service URL for every build:

```powershell
flutter pub get
flutter run --dart-define=PRICEGENT_API_BASE_URL=https://your-service.onrender.com
```

Replace the example URL with your Render service URL (no trailing slash).
Android emulators and physical phones use the same hosted URL. The app has no
laptop-hosted default; if the URL is omitted, study generation reports a
configuration error.

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
