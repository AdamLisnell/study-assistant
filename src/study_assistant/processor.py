"""Main processing logic for Study Assistant."""

from pathlib import Path
from typing import Dict

from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

from .config import AppConfig
from .file_handler import FileHandler
from .openai_client import StudyAssistantClient
from .subject_parser import SubjectParser
from .utils.logger import setup_logger

logger = setup_logger(__name__)
console = Console()


class NoteProcessor:
    """Process notes and generate study materials."""
    
    def __init__(self, config: AppConfig):
        """
        Initialize note processor.
        
        Args:
            config: Application configuration
        """
        self.config = config
        self.file_handler = FileHandler(
            config.notes_incoming_dir,
            config.processed_index_path
        )
        self.ai_client = StudyAssistantClient(
            api_key=config.openai_api_key,
            model=config.openai_model
        )
    
    def process_all_notes(self) -> Dict[str, bool]:
        """
        Process all unprocessed notes in incoming directory.
        
        Returns:
            Dictionary mapping filename to success status
        """
        files = self.file_handler.list_incoming_files()
        
        if not files:
            console.print("[yellow]No files found to process[/yellow]")
            return {}
        
        processed_index = self.file_handler.load_processed_index()
        results: Dict[str, bool] = {}
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console
        ) as progress:
            
            task = progress.add_task(
                f"Processing {len(files)} file(s)...",
                total=len(files)
            )
            
            for filepath in files:
                filename = filepath.name
                
                # Skip already processed files
                if self.file_handler.is_processed(filename, processed_index):
                    logger.info(f"Skipping already processed file: {filename}")
                    progress.advance(task)
                    continue
                
                # Process the file
                success = self._process_single_note(filepath)
                results[filename] = success
                
                # Update index if successful
                if success:
                    self.file_handler.mark_processed(filename, processed_index)
                    self.file_handler.save_processed_index(processed_index)
                
                progress.advance(task)
        
        # Summary
        successful = sum(1 for v in results.values() if v)
        console.print(f"\n[green]✓[/green] Successfully processed {successful}/{len(results)} file(s)")
        
        return results
    
    def _process_single_note(self, filepath: Path) -> bool:
        """
        Process a single note file.
        
        Args:
            filepath: Path to the note file
        
        Returns:
            True if processing was successful
        """
        filename = filepath.name
        logger.info(f"Processing: {filename}")
        
        try:
            # Extract subject
            subject = SubjectParser.extract_subject(filename)
            if not subject:
                logger.error(f"Invalid filename format: {filename}")
                console.print(f"[red]✗[/red] Invalid filename format: {filename}")
                return False
            
            # Read note content
            note_content = self.file_handler.read_note_file(filepath)
            
            # Generate study material
            console.print(f"  Generating study material for [cyan]{subject}[/cyan]...")
            study_material = self.ai_client.generate_study_material(note_content)
            
            if not study_material:
                logger.error(f"Failed to generate study material for {filename}")
                console.print(f"[red]✗[/red] Failed to generate material for {filename}")
                return False
            
            # Save output
            subject_folder = SubjectParser.get_subject_folder(
                self.config.notes_incoming_dir.parent,
                subject
            )
            output_filename = SubjectParser.generate_output_filename(filename)
            output_path = subject_folder / output_filename
            
            self.file_handler.save_output(output_path, study_material)
            
            # Display success message with absolute path if relative path fails
            try:
                rel_path = output_path.relative_to(Path.cwd())
                console.print(f"[green]✓[/green] Saved to {rel_path}")
            except ValueError:
                console.print(f"[green]✓[/green] Saved to {output_path}")
            
            return True
            
        except Exception as e:
            logger.exception(f"Error processing {filename}: {e}")
            console.print(f"[red]✗[/red] Error processing {filename}: {e}")
            return False
