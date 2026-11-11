from fastapi import FastAPI, HTTPException, Response, status

from app.learning_engine import (
    ProviderNotConfiguredError,
    ProviderResponseError,
    generate_cross_section_image,
    generate_study_report,
)
from app.schemas import StudyReport, StudyRequest

app = FastAPI(title="Pricegent Learning API", version="0.1.0")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/v1/studies/process", response_model=StudyReport)
async def process_study(request: StudyRequest) -> StudyReport:
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
async def illustrate_study(request: StudyRequest) -> Response:
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
