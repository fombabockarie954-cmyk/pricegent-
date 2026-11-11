from typing import Literal

from pydantic import BaseModel, Field, model_validator


class StudyRequest(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    source: str = Field(min_length=20, max_length=20_000)


class Concept(BaseModel):
    id: str = Field(pattern=r"^[a-z0-9_-]+$", max_length=40)
    name: str = Field(min_length=1, max_length=100)
    definition: str = Field(min_length=1, max_length=500)
    source_quote: str = Field(min_length=1, max_length=500)


class ConceptRelationship(BaseModel):
    source_id: str = Field(min_length=1, max_length=40)
    target_id: str = Field(min_length=1, max_length=40)
    relation: Literal[
        "depends_on",
        "causes",
        "contrasts_with",
        "part_of",
        "example_of",
        "related_to",
        "derived_from",
    ]


class SenseStep(BaseModel):
    central_idea: str = Field(min_length=1, max_length=500)
    source_evidence: str = Field(min_length=1, max_length=500)


class ExaggerateStep(BaseModel):
    concept_id: str = Field(min_length=1, max_length=40)
    imagined_scene: str = Field(min_length=1, max_length=1200)
    what_stays_true: str = Field(min_length=1, max_length=600)
    where_it_breaks: str = Field(min_length=1, max_length=600)


class EnergizeStep(BaseModel):
    real_world_application: str = Field(min_length=1, max_length=800)
    try_this: str = Field(min_length=1, max_length=500)


class SeeExplanation(BaseModel):
    sense: SenseStep
    exaggerate: ExaggerateStep
    energize: EnergizeStep


class RecallQuestion(BaseModel):
    question: str = Field(min_length=1, max_length=300)
    answer: str = Field(min_length=1, max_length=500)
    level: Literal["remember", "explain", "apply"]


class StudyReport(BaseModel):
    summary: str = Field(min_length=1, max_length=700)
    fundamental_principle: str = Field(min_length=1, max_length=500)
    concepts: list[Concept] = Field(min_length=2, max_length=8)
    relationships: list[ConceptRelationship] = Field(min_length=1, max_length=12)
    see: SeeExplanation
    recall_questions: list[RecallQuestion] = Field(min_length=3, max_length=6)

    @model_validator(mode="after")
    def validate_concept_references(self) -> "StudyReport":
        concept_ids = {concept.id for concept in self.concepts}
        if len(concept_ids) != len(self.concepts):
            raise ValueError("Concept ids must be unique.")
        if self.see.exaggerate.concept_id not in concept_ids:
            raise ValueError("The imagined example must reference an extracted concept.")
        for relationship in self.relationships:
            if (
                relationship.source_id not in concept_ids
                or relationship.target_id not in concept_ids
            ):
                raise ValueError("Concept relationships must reference extracted concepts.")
        return self

    def validate_source_quotes(self, source: str) -> None:
        for concept in self.concepts:
            if concept.source_quote not in source:
                raise ValueError(
                    f'The source quote for "{concept.name}" is not present verbatim.'
                )
        if self.see.sense.source_evidence not in source:
            raise ValueError("The SENSE evidence must be present in the supplied source.")
