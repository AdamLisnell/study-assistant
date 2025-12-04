"""OpenAI API client for Study Assistant."""

from typing import Optional

from openai import OpenAI, OpenAIError

from .config import AppConfig
from .utils.logger import setup_logger

logger = setup_logger(__name__)


class StudyAssistantClient:
    """Client for interacting with OpenAI API."""
    
    SYSTEM_PROMPT = """You are an expert study assistant. Your task is to help students 
learn by processing their notes and creating study materials.

Always structure your output in clear Markdown sections with the following format:

# Summary
[Concise summary of main concepts, max 300 words]

# Key Points
- [Important point 1]
- [Important point 2]
- [etc.]

# Study Questions
1. **Question:** [Question text]
   **Answer:** [Detailed answer]

[Repeat for 10 questions]

# Flashcards
**Card 1**
- **Front:** [Question]
- **Back:** [Answer]

[Repeat for multiple cards]

Be precise, educational, and focus on understanding core concepts."""
    
    def __init__(self, api_key: str, model: str = "gpt-4-turbo-preview"):
        """
        Initialize OpenAI client.
        
        Args:
            api_key: OpenAI API key
            model: Model to use
        """
        self.model = model
        self.client = OpenAI(api_key=api_key)
        logger.debug(f"Initialized OpenAI client with model: {model}")
    
    def build_prompt(self, note_content: str) -> str:
        """
        Build user prompt from note content.
        
        Args:
            note_content: Raw note text
        
        Returns:
            Formatted prompt for the AI
        """
        return f"""Please process these lecture notes and create comprehensive study materials:

---
{note_content}
---

Create the output following the structure I specified in the system prompt."""
    
    def generate_study_material(
        self,
        note_content: str,
        max_retries: int = 3
    ) -> Optional[str]:
        """
        Generate study material from note content.
        
        Args:
            note_content: Raw note text
            max_retries: Maximum number of retry attempts
        
        Returns:
            Generated study material in Markdown format, or None on failure
        """
        prompt = self.build_prompt(note_content)
        
        for attempt in range(max_retries):
            try:
                logger.debug(f"Calling OpenAI API (attempt {attempt + 1}/{max_retries})")
                
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=[
                        {"role": "system", "content": self.SYSTEM_PROMPT},
                        {"role": "user", "content": prompt}
                    ],
                    max_tokens=2000,
                    temperature=0.7
                )
                
                content = response.choices[0].message.content
                
                if content:
                    logger.info(
                        f"Generated {len(content)} characters of study material "
                        f"(tokens used: {response.usage.total_tokens})"
                    )
                    return content
                else:
                    logger.warning("Received empty response from OpenAI")
                    
            except OpenAIError as e:
                logger.error(f"OpenAI API error (attempt {attempt + 1}): {e}")
                if attempt == max_retries - 1:
                    logger.error("Max retries reached, giving up")
                    return None
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                return None
        
        return None
