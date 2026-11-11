import json
import os
from threading import Lock
from typing import Any

import firebase_admin
from firebase_admin import auth, credentials, exceptions


class FirebaseAuthConfigurationError(Exception):
    pass


class InvalidFirebaseTokenError(Exception):
    pass


_app = None
_app_lock = Lock()


def _firebase_app() -> firebase_admin.App:
    global _app
    if _app is not None:
        return _app

    with _app_lock:
        if _app is not None:
            return _app
        account_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
        if not account_json:
            raise FirebaseAuthConfigurationError(
                "Firebase authentication is not configured."
            )
        try:
            account_info = json.loads(account_json)
            if not isinstance(account_info, dict):
                raise ValueError("Service account JSON must be an object.")
            credential = credentials.Certificate(account_info)
            _app = firebase_admin.initialize_app(
                credential,
                name="pricegent-auth",
            )
        except (json.JSONDecodeError, TypeError, ValueError) as error:
            raise FirebaseAuthConfigurationError(
                "Firebase service account configuration is invalid."
            ) from error
    return _app


def verify_firebase_id_token(token: str) -> dict[str, Any]:
    try:
        return auth.verify_id_token(token, app=_firebase_app())
    except FirebaseAuthConfigurationError:
        raise
    except (exceptions.FirebaseError, ValueError) as error:
        raise InvalidFirebaseTokenError from error
