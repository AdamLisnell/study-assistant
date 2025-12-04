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
    openai_api_key: str = Field(..., env="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-4-turbo-preview", env="OPENAI_MODEL")
    
    # Directory settings
    notes_incoming_dir: Path = Field(
        default=Path("./notes/incoming"),
        env="NOTES_INCOMING_DIR"
    )
    processed_index_path: Path = Field(
        default=Path("./processed_index.json"),
        env="PROCESSED_INDEX_PATH"
    )
    
    # Logging
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    
    # Rate limiting
    max_requests_per_minute: int = Field(default=50, env="MAX_REQUESTS_PER_MINUTE")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
    
    @field_validator("notes_incoming_dir")
    def validate_incoming_dir(cls, v: Path) -> Path:
        """Ensure incoming directory exists."""
        v.mkdir(parents=True, exist_ok=True)
        return v


def load_config() -> AppConfig:
    """Load configuration from environment and .env file."""
    load_dotenv()
    return AppConfig()
