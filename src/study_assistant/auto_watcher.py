"""Automatic file watcher for NotePal."""

import time
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileCreatedEvent, FileModifiedEvent

from .processor import NoteProcessor
from .config import load_config
from .utils.logger import setup_logger

logger = setup_logger(__name__)


class NoteWatcher(FileSystemEventHandler):
    """Watch for new notes and process them automatically."""
    
    def __init__(self, processor: NoteProcessor):
        self.processor = processor
        self.processing_files = set()
        self.supported_extensions = {".txt", ".md", ".markdown", ".pdf", ".docx", ".doc"}
    
    def on_created(self, event):
        """Handle new file creation."""
        if event.is_directory:
            return
        
        self._handle_file(event.src_path)
    
    def on_modified(self, event):
        """Handle file modification."""
        if event.is_directory:
            return
        
        # Wait a bit to ensure file is fully written
        time.sleep(1)
        self._handle_file(event.src_path)
    
    def _handle_file(self, file_path: str | bytes | Path) -> None:
        """Process a file if it's supported."""
        # Convert to Path, handling bytes/str/Path
        if isinstance(file_path, bytes):
            filepath: Path = Path(file_path.decode('utf-8'))
        elif isinstance(file_path, str):
            filepath: Path = Path(file_path)
        elif isinstance(file_path, Path):
            filepath: Path = file_path
        else:
            # Fallback for any unexpected types
            filepath: Path = Path(str(file_path))
        
        # Now filepath is guaranteed to be Path type
        
        # Check if supported file type
        if filepath.suffix.lower() not in self.supported_extensions:
            return
        
        # Avoid processing the same file multiple times
        if filepath in self.processing_files:
            return
        
        logger.info(f" New file detected: {filepath.name}")
        print(f"\n New file detected: {filepath.name}")
        print(" Auto-processing...")
        
        self.processing_files.add(filepath)
        
        try:
            # Process the note
            success = self.processor._process_single_note(filepath)
            
            if success:
                logger.info(f" Auto-processed: {filepath.name}")
                print(f" Auto-processed successfully!\n")
            else:
                logger.error(f" Failed to process: {filepath.name}")
                print(f" Processing failed\n")
        
        finally:
            # Remove from processing set after a delay
            time.sleep(2)
            self.processing_files.discard(filepath)


def start_watching():
    """Start watching the incoming directory."""
    config = load_config()
    processor = NoteProcessor(config)
    
    incoming_dir = config.notes_incoming_dir
    
    print(f"""
╔═══════════════════════════════════════════════════════╗
║               NotePal Auto-Watcher                    ║
╚═══════════════════════════════════════════════════════╝

Watching: {incoming_dir}
Auto-processing enabled

Drop your notes into the folder and they'll be processed automatically!

Press Ctrl+C to stop...
""")
    
    event_handler = NoteWatcher(processor)
    observer = Observer()
    observer.schedule(event_handler, str(incoming_dir), recursive=False)
    observer.start()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\n\n NotePal Auto-Watcher stopped")
    
    observer.join()


if __name__ == "__main__":
    start_watching()
