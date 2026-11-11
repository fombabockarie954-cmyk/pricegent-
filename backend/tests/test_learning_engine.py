import base64

import pytest

import httpx

from app import learning_engine
from app.learning_engine import (
    ProviderNotConfiguredError,
    ProviderResponseError,
    _provider_settings,
    generate_cross_section_image,
)


def test_local_provider_does_not_require_api_key(monkeypatch) -> None:
    monkeypatch.delenv("PRICEGENT_LLM_API_KEY", raising=False)
    monkeypatch.setenv("PRICEGENT_LLM_BASE_URL", "http://127.0.0.1:1234/v1")
    monkeypatch.setenv("PRICEGENT_LLM_MODEL", "local-model")

    assert _provider_settings() == (
        "http://127.0.0.1:1234/v1",
        None,
        "local-model",
    )


def test_remote_provider_still_requires_api_key(monkeypatch) -> None:
    monkeypatch.delenv("PRICEGENT_LLM_API_KEY", raising=False)
    monkeypatch.setenv("PRICEGENT_LLM_BASE_URL", "https://api.openai.com/v1")
    monkeypatch.setenv("PRICEGENT_LLM_MODEL", "remote-model")

    with pytest.raises(ProviderNotConfiguredError, match="PRICEGENT_LLM_API_KEY"):
        _provider_settings()


@pytest.mark.anyio
async def test_image_generation_uses_configured_gemini_model(monkeypatch) -> None:
    key = "test-image-key"
    image = b"test-image-bytes"
    monkeypatch.setenv("PRICEGENT_IMAGE_API_KEY", key)
    monkeypatch.setenv("PRICEGENT_IMAGE_MODEL", "test-image-model")
    requests: list[httpx.Request] = []

    def handle_request(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        return httpx.Response(
            200,
            json={
                "candidates": [
                    {
                        "content": {
                            "parts": [
                                {
                                    "inlineData": {
                                        "mimeType": "image/png",
                                        "data": base64.b64encode(image).decode(),
                                    }
                                }
                            ]
                        }
                    }
                ]
            },
        )

    async_client = httpx.AsyncClient

    def create_client(*, timeout: float) -> httpx.AsyncClient:
        return async_client(
            transport=httpx.MockTransport(handle_request),
            timeout=timeout,
        )

    monkeypatch.setattr(learning_engine.httpx, "AsyncClient", create_client)
    result, mime_type = await generate_cross_section_image(
        "Photosynthesis",
        "Plants have chlorophyll in their leaves.",
    )

    assert result == image
    assert mime_type == "image/png"
    assert len(requests) == 1
    assert str(requests[0].url) == (
        "https://generativelanguage.googleapis.com/v1beta/"
        "models/test-image-model:generateContent"
    )
    assert requests[0].headers["x-goog-api-key"] == key
    payload = requests[0].read().decode()
    assert "Photosynthesis" in payload
    assert "chlorophyll" in payload


@pytest.mark.anyio
async def test_image_generation_requires_a_gemini_api_key(monkeypatch) -> None:
    monkeypatch.delenv("PRICEGENT_IMAGE_API_KEY", raising=False)
    monkeypatch.delenv("PRICEGENT_LLM_API_KEY", raising=False)

    with pytest.raises(ProviderNotConfiguredError, match="PRICEGENT_IMAGE_API_KEY"):
        await generate_cross_section_image("Photosynthesis", "Study material.")


@pytest.mark.anyio
async def test_non_gemini_learning_key_is_not_reused_for_image_generation(
    monkeypatch,
) -> None:
    monkeypatch.delenv("PRICEGENT_IMAGE_API_KEY", raising=False)
    monkeypatch.setenv("PRICEGENT_LLM_API_KEY", "text-provider-key")
    monkeypatch.setenv("PRICEGENT_LLM_BASE_URL", "https://api.openai.com/v1")

    with pytest.raises(ProviderNotConfiguredError, match="PRICEGENT_IMAGE_API_KEY"):
        await generate_cross_section_image("Photosynthesis", "Study material.")


@pytest.mark.anyio
async def test_gemini_request_uses_configured_bearer_key(monkeypatch) -> None:
    key = "test-gemini-key"
    monkeypatch.setenv("PRICEGENT_LLM_API_KEY", key)
    monkeypatch.setenv(
        "PRICEGENT_LLM_BASE_URL",
        "https://generativelanguage.googleapis.com/v1beta/openai",
    )
    monkeypatch.setenv("PRICEGENT_LLM_MODEL", "gemini-test-model")
    requests: list[httpx.Request] = []

    def handle_request(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        return httpx.Response(401)

    async_client = httpx.AsyncClient

    def create_client(*, timeout: float) -> httpx.AsyncClient:
        return async_client(
            transport=httpx.MockTransport(handle_request),
            timeout=timeout,
        )

    monkeypatch.setattr(learning_engine.httpx, "AsyncClient", create_client)

    with pytest.raises(ProviderResponseError):
        await learning_engine.generate_study_report(
            "Java",
            "Java is an object oriented programming language used for many applications.",
        )

    assert len(requests) == 1
    assert str(requests[0].url) == (
        "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
    )
    assert requests[0].headers["Authorization"] == f"Bearer {key}"
