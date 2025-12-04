"""Subject name extraction from filenames."""

import re
from pathlib import Path
from typing import Optional

from .utils.logger import setup_logger

logger = setup_logger(__name__)


class SubjectParser:
    """Parse subject names from note filenames."""
    
    # Valid subject name pattern (alphanumeric + Swedish chars + hyphens)
    SUBJECT_PATTERN = re.compile(r"^([a-zA-ZåäöÅÄÖ0-9\-]+)_")
    
    @classmethod
    def extract_subject(cls, filename: str) -> Optional[str]:
        """
        Extract subject name from filename.
        
        Expected format: <subject>_rest-of-name.ext
        Example: cybersäkerhet_föreläsning1.txt -> cybersäkerhet
        
        Args:
            filename: Name of the file (not full path)
        
        Returns:
            Subject name if valid format, None otherwise
        """
        match = cls.SUBJECT_PATTERN.match(filename)
        
        if match:
            subject = match.group(1).lower()
            logger.debug(f"Extracted subject '{subject}' from '{filename}'")
            return subject
        
        logger.warning(f"Could not extract subject from '{filename}' - invalid format")
        return None
    
    @classmethod
    def get_subject_folder(cls, base_dir: Path, subject: str) -> Path:
        """
        Get or create subject folder.
        
        Args:
            base_dir: Base directory for notes
            subject: Subject name
        
        Returns:
            Path to subject folder
        """
        subject_folder = base_dir / subject
        subject_folder.mkdir(parents=True, exist_ok=True)
        logger.debug(f"Subject folder ensured: {subject_folder}")
        return subject_folder
    
    @classmethod
    def generate_output_filename(cls, input_filename: str, suffix: str = "_study") -> str:
        """
        Generate output filename from input filename.
        
        Args:
            input_filename: Original note filename
            suffix: Suffix to add before extension
        
        Returns:
            Output filename
        """
        stem = Path(input_filename).stem
        return f"{stem}{suffix}.md"
