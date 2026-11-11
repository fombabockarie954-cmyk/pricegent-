# Pricegent API

This service turns learner-supplied text into a structured study report:
source-grounded concepts, relationships, a SENSE / EXAGGERATE / ENERGIZE
explanation, and retrieval-practice questions.

The model endpoint is configurable and follows the OpenAI Chat Completions
request/response format. The app does not contain model credentials.

## Deploy to Render

The repository's [Render Blueprint](../render.yaml) creates a hosted Python web
service with `/health` configured as its health check. In Render, create a
Blueprint from the repository, then set these environment variables for the
service:

- `PRICEGENT_LLM_API_KEY`
- `PRICEGENT_LLM_MODEL`
- `PRICEGENT_LLM_BASE_URL` (optional; defaults to `https://api.openai.com/v1`)
- `PRICEGENT_IMAGE_API_KEY` (optional; needed for Gemini image generation
  unless `PRICEGENT_LLM_API_KEY` is a Gemini key)
- `FIREBASE_SERVICE_ACCOUNT_JSON` (required; Firebase Admin service-account JSON)

Use Render's secret environment-variable settings for keys and the Firebase
service-account JSON. Never commit or share the service-account JSON. Once
deployed, verify `https://<service-name>.onrender.com/health` returns
`{"status":"ok"}` and configure the app with that HTTPS base URL.

Study and illustration requests require a valid Firebase ID token. The public
health endpoint does not expose study functionality. Add quotas or rate limits
before scaling the service or allowing broad public use to further constrain
model spend.

## Configure Firebase authentication

In Firebase, register an Android app using package name
`com.pricegent.pricegent_mobile`, enable Google as an Authentication provider,
and add the app's Android signing SHA fingerprints. The mobile app uses the
Firebase API key, app ID, project ID, messaging sender ID, and Web OAuth client
ID as build-time client configuration. The backend verifies ID tokens using
the Firebase Admin SDK and `FIREBASE_SERVICE_ACCOUNT_JSON`; the private service
account key must remain only in Render's secret settings.

## Run locally for development

From `backend`, configure the local `.env` as follows:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
notepad .env
```

For Gemini, put these settings in the local `backend\.env` file, replacing the
placeholder with a newly generated API key:

```dotenv
PRICEGENT_LLM_API_KEY=replace-with-your-new-key
PRICEGENT_LLM_BASE_URL=https://generativelanguage.googleapis.com/v1beta/openai
PRICEGENT_LLM_MODEL=gemini-3.8-flash
```

`.env` is ignored by git. Keep the key there on your computer; never commit it
or paste it into chat. Start the API from the `backend` directory:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --env-file .env --host 127.0.0.1 --port 8000
```

The Gemini URL and model above use Google's OpenAI-compatible Gemini API. For
another provider, set the corresponding base URL and model in `.env`. A local
OpenAI-compatible server on `localhost` does not require an API key.

Cross-section illustrations use Google's Gemini image-generation API. With the
Gemini settings above, the existing API key is reused automatically. You can
override the image provider settings when needed:

```dotenv
PRICEGENT_IMAGE_API_KEY=replace-with-your-image-api-key
PRICEGENT_IMAGE_MODEL=gemini-2.5-flash-image
# Optional; this is the default Google Gemini API base URL.
PRICEGENT_IMAGE_BASE_URL=https://generativelanguage.googleapis.com/v1beta
```

The study guide remains available if image generation is not configured. The
learner can request an illustration separately from the study result screen.

For local development only, run Flutter from the project root in a second
PowerShell terminal. Along with the Firebase build options documented in the
root README, use `10.0.2.2` for an Android emulator or `adb reverse` and
`127.0.0.1` for a USB-connected Android phone:

```powershell
cd .. # Move from backend/ to the Flutter project root (pricegent_mobile/)
flutter run --dart-define=PRICEGENT_API_BASE_URL=http://10.0.2.2:8000
```

For USB, run `adb reverse tcp:8000 tcp:8000` and pass
`--dart-define=PRICEGENT_API_BASE_URL=http://127.0.0.1:8000`. Neither local URL
is used as an app default.

If Firebase credentials or model settings are missing, the API reports an
explicit configuration error; it does not return a fake success-shaped report.
## Test

```powershell
python -m pip install -e ".[dev]"
python -m pytest
```
