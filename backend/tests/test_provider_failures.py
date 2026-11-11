import pytest
import httpx

from app import learning_engine
from app.learning_engine import ProviderResponseError


@pytest.mark.anyio
async def test_temporary_provider_overload_is_reported_as_retryable(monkeypatch) -> None:
    monkeypatch.setenv("PRICEGENT_LLM_API_KEY", "test-gemini-key")
    monkeypatch.setenv(
        "PRICEGENT_LLM_BASE_URL",
        "https://generativelanguage.googleapis.com/v1beta/openai",
    )
    monkeypatch.setenv("PRICEGENT_LLM_MODEL", "gemini-test-model")

    def handle_request(request: httpx.Request) -> httpx.Response:
        return httpx.Response(503, json={"error": {"message": "temporarily busy"}})

    async_client = httpx.AsyncClient

    def create_client(*, timeout: float) -> httpx.AsyncClient:
        return async_client(
            transport=httpx.MockTransport(handle_request),
            timeout=timeout,
        )

    monkeypatch.setattr(learning_engine.httpx, "AsyncClient", create_client)

    with pytest.raises(ProviderResponseError, match="temporarily busy") as error:
        await learning_engine.generate_study_report(
            "Java",
            "Java is an object oriented programming language used for many applications.",
        )

    assert error.value.status_code == 503
