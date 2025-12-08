"""Configuration management for Study Assistant."""

import os
from pathlib import Path
from typing import Optional

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings
from dotenv import load_dotenv


class AppConfig(BaseSettings):
    """Application configuration with environment variable support."""
    
    # OpenAI settings
    openai_api_key: str = Field(..., validation_alias="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-4o-mini", validation_alias="OPENAI_MODEL")
    
    # Directory settings
    notes_incoming_dir: Path = Field(
        default=Path("./notes/incoming"),
        validation_alias="NOTES_INCOMING_DIR"
    )
    notes_output_dir: Path = Field(
        default=Path("./notes"),
        validation_alias="NOTES_OUTPUT_DIR"
    )
    processed_index_path: Path = Field(
        default=Path("./processed_index.json"),
        validation_alias="PROCESSED_INDEX_PATH"
    )
    
    # Logging
    log_level: str = Field(default="INFO", validation_alias="LOG_LEVEL")
    
    # Rate limiting
    max_requests_per_minute: int = Field(default=50, validation_alias="MAX_REQUESTS_PER_MINUTE")
    
    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8"
    }
    
    @field_validator("notes_incoming_dir", "notes_output_dir")
    @classmethod
    def validate_dirs(cls, v: Path) -> Path:
        """Ensure directories exist."""
        v.mkdir(parents=True, exist_ok=True)
        return v


def load_config() -> AppConfig:
    """Load configuration from environment and .env file."""
    load_dotenv()
    return AppConfig() # type: ignore