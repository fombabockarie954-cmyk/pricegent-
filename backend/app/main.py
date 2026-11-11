from fastapi import Depends, FastAPI, Header, HTTPException, Response, status

from app.firebase_auth import (
    FirebaseAuthConfigurationError,
    InvalidFirebaseTokenError,
    verify_firebase_id_token,
)
from app.learning_engine import (
    ProviderNotConfiguredError,
    ProviderResponseError,
    generate_cross_section_image,
    generate_study_report,
)
from app.schemas import StudyReport, StudyRequest

app = FastAPI(title="Pricegent Learning API", version="0.1.0")


def require_authenticated_user(
    authorization: str | None = Header(default=None),
) -> str:
    if authorization is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sign in to use the learning service.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    scheme, separator, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not separator or not token.strip():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="A valid Firebase bearer token is required.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        claims = verify_firebase_id_token(token.strip())
    except FirebaseAuthConfigurationError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
    except InvalidFirebaseTokenError as error:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your sign-in session is invalid. Sign in again.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from error

    user_id = claims.get("uid")
    if not isinstance(user_id, str) or not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="The sign-in token has no user identity.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user_id


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/studies/process", response_model=StudyReport)
async def process_study(
    request: StudyRequest,
    _user_id: str = Depends(require_authenticated_user),
) -> StudyReport:
    try:
        return await generate_study_report(request.title, request.source)
    except ProviderNotConfiguredError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
    except ProviderResponseError as error:
        raise HTTPException(
            status_code=error.status_code,
            detail=str(error),
        ) from error


@app.post("/v1/studies/illustrate")
async def illustrate_study(
    request: StudyRequest,
    _user_id: str = Depends(require_authenticated_user),
) -> Response:
    try:
        image, mime_type = await generate_cross_section_image(
            request.title,
            request.source,
        )
        return Response(content=image, media_type=mime_type)
    except ProviderNotConfiguredError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
    except ProviderResponseError as error:
        raise HTTPException(
            status_code=error.status_code,
            detail=str(error),
        ) from error
