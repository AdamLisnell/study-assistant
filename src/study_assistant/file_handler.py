"""File handling operations for Study Assistant."""

import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List

from .utils.logger import setup_logger

logger = setup_logger(__name__)


class FileHandler:
    """Handle file operations for notes and processed index."""
    
    SUPPORTED_EXTENSIONS = {".txt", ".md", ".markdown"}
    
    def __init__(self, incoming_dir: Path, index_path: Path):
        """
        Initialize file handler.
        
        Args:
            incoming_dir: Directory containing incoming notes
            index_path: Path to processed files index
        """
        self.incoming_dir = incoming_dir
        self.index_path = index_path
        self._ensure_directories()
    
    def _ensure_directories(self) -> None:
        """Ensure required directories exist."""
        self.incoming_dir.mkdir(parents=True, exist_ok=True)
        logger.debug(f"Incoming directory ready: {self.incoming_dir}")
    
    def list_incoming_files(self) -> List[Path]:
        """
        List all unprocessed note files in incoming directory.
        
        Returns:
            List of file paths to process
        """
        files = []
        
        for ext in self.SUPPORTED_EXTENSIONS:
            files.extend(self.incoming_dir.glob(f"*{ext}"))
        
        logger.info(f"Found {len(files)} file(s) in incoming directory")
        return sorted(files)
    
    def read_note_file(self, filepath: Path) -> str:
        """
        Read content from a note file.
        
        Args:
            filepath: Path to note file
        
        Returns:
            File content as string
        """
        try:
            content = filepath.read_text(encoding="utf-8")
            logger.debug(f"Read {len(content)} characters from {filepath.name}")
            return content
        except Exception as e:
            logger.error(f"Error reading {filepath}: {e}")
            raise
    
    def save_output(self, output_path: Path, content: str) -> None:
        """
        Save processed content to file.
        
        Args:
            output_path: Path where to save the output
            content: Content to save
        """
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(content, encoding="utf-8")
            logger.info(f"Saved output to {output_path}")
        except Exception as e:
            logger.error(f"Failed to save output to {output_path}: {e}")
            raise
    
    def load_processed_index(self) -> Dict[str, str]:
        """
        Load index of processed files.
        
        Returns:
            Dictionary mapping filename to timestamp
        """
        if not self.index_path.exists():
            logger.debug("No existing processed index found")
            return {}
        
        try:
            with open(self.index_path, "r", encoding="utf-8") as f:
                index = json.load(f)
            logger.debug(f"Loaded processed index with {len(index)} entries")
            return index
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in processed index: {e}")
            return {}
    
    def save_processed_index(self, index: Dict[str, str]) -> None:
        """
        Save processed files index.
        
        Args:
            index: Dictionary mapping filename to timestamp
        """
        try:
            with open(self.index_path, "w", encoding="utf-8") as f:
                json.dump(index, f, indent=2, ensure_ascii=False)
            logger.debug(f"Saved processed index with {len(index)} entries")
        except Exception as e:
            logger.error(f"Failed to save processed index: {e}")
            raise
    
    def is_processed(self, filename: str, index: Dict[str, str]) -> bool:
        """Check if a file has already been processed."""
        return filename in index
    
    def mark_processed(self, filename: str, index: Dict[str, str]) -> None:
        """Mark a file as processed in the index."""
        index[filename] = datetime.now().isoformat()
        logger.debug(f"Marked {filename} as processed")
