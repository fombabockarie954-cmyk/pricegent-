import pytest
from httpx import ASGITransport, AsyncClient

from app import main
from app.schemas import StudyReport


@pytest.fixture
def anyio_backend() -> str:
    return "asyncio"


def _sample_report() -> StudyReport:
    return StudyReport.model_validate(
        {
            "summary": "Plants turn light into stored chemical energy.",
            "fundamental_principle": "Light energy can drive chemical change.",
            "concepts": [
                {
                    "id": "light",
                    "name": "Light energy",
                    "definition": "Energy carried by sunlight.",
                    "source_quote": "Plants absorb light energy.",
                },
                {
                    "id": "chemical",
                    "name": "Chemical energy",
                    "definition": "Energy stored in chemical bonds.",
                    "source_quote": "They store energy as glucose.",
                },
            ],
            "relationships": [
                {
                    "source_id": "light",
                    "target_id": "chemical",
                    "relation": "causes",
                }
            ],
            "see": {
                "sense": {
                    "central_idea": "Plants store some absorbed light energy.",
                    "source_evidence": "Plants absorb light energy.",
                },
                "exaggerate": {
                    "concept_id": "light",
                    "imagined_scene": "Imagine every leaf as a tiny solar workshop.",
                    "what_stays_true": "Light supplies energy to the process.",
                    "where_it_breaks": "Leaves are not factories with workers.",
                },
                "energize": {
                    "real_world_application": "The stored energy becomes part of food.",
                    "try_this": "Trace the energy path from sunlight to a meal.",
                },
            },
            "recall_questions": [
                {
                    "question": "What does sunlight provide?",
                    "answer": "Energy.",
                    "level": "remember",
                },
                {
                    "question": "Where is some energy stored?",
                    "answer": "In glucose.",
                    "level": "explain",
                },
                {
                    "question": "Trace the energy path.",
                    "answer": "From sunlight into stored chemical energy.",
                    "level": "apply",
                },
            ],
        }
    )


@pytest.mark.anyio
async def test_health_endpoint() -> None:
    async with AsyncClient(
        transport=ASGITransport(app=main.app),
        base_url="http://test",
    ) as client:
        response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.anyio
async def test_process_returns_complete_study_report(monkeypatch) -> None:
    async def fake_generate_report(title: str, source: str) -> StudyReport:
        report = _sample_report()
        report.validate_source_quotes(source)
        return report

    monkeypatch.setattr(main, "generate_study_report", fake_generate_report)
    async with AsyncClient(
        transport=ASGITransport(app=main.app),
        base_url="http://test",
    ) as client:
        response = await client.post(
            "/v1/studies/process",
            json={
                "title": "Photosynthesis",
                "source": (
                    "Plants absorb light energy. They store energy as glucose. "
                    "This process supports life."
                ),
            },
        )

    assert response.status_code == 200
    body = response.json()
    assert len(body["concepts"]) == 2
    assert body["see"]["exaggerate"]["where_it_breaks"]
    assert len(body["recall_questions"]) == 3


@pytest.mark.anyio
async def test_illustrate_returns_generated_image_bytes(monkeypatch) -> None:
    async def fake_generate_illustration(
        title: str,
        source: str,
    ) -> tuple[bytes, str]:
        assert title == "Photosynthesis"
        assert source.startswith("Plants absorb light energy.")
        return b"generated-image", "image/png"

    monkeypatch.setattr(main, "generate_cross_section_image", fake_generate_illustration)
    async with AsyncClient(
        transport=ASGITransport(app=main.app),
        base_url="http://test",
    ) as client:
        response = await client.post(
            "/v1/studies/illustrate",
            json={
                "title": "Photosynthesis",
                "source": (
                    "Plants absorb light energy. They store energy as glucose. "
                    "This process supports life."
                ),
            },
        )

    assert response.status_code == 200
    assert response.headers["content-type"] == "image/png"
    assert response.content == b"generated-image"


@pytest.mark.anyio
async def test_process_rejects_source_that_is_too_short() -> None:
    async with AsyncClient(
        transport=ASGITransport(app=main.app),
        base_url="http://test",
    ) as client:
        response = await client.post(
            "/v1/studies/process",
            json={"title": "Short", "source": "Too short"},
        )

    assert response.status_code == 422


@pytest.mark.anyio
async def test_process_reports_missing_model_configuration(monkeypatch) -> None:
    monkeypatch.delenv("PRICEGENT_LLM_API_KEY", raising=False)
    monkeypatch.delenv("PRICEGENT_LLM_MODEL", raising=False)
    async with AsyncClient(
        transport=ASGITransport(app=main.app),
        base_url="http://test",
    ) as client:
        response = await client.post(
            "/v1/studies/process",
            json={
                "title": "Photosynthesis",
                "source": (
                    "Plants absorb light energy. They store energy as glucose. "
                    "This process supports life."
                ),
            },
        )

    assert response.status_code == 503
    assert "PRICEGENT_LLM_API_KEY" in response.json()["detail"]
