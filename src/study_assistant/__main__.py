"""Command-line interface for Study Assistant."""

from pathlib import Path
from typing import Optional

import typer
from rich.console import Console

from .config import load_config
from .processor import NoteProcessor
from .utils.logger import setup_logger

app = typer.Typer(
    name="study-assistant",
    help="AI-powered study assistant that processes notes automatically"
)
console = Console()


@app.command()
def process(
    incoming_dir: Optional[Path] = typer.Option(
        None,
        "--incoming-dir",
        "-i",
        help="Directory containing incoming notes"
    ),
    log_level: Optional[str] = typer.Option(
        None,
        "--log-level",
        "-l",
        help="Logging level (DEBUG, INFO, WARNING, ERROR)"
    )
) -> None:
    """Process all unprocessed notes in the incoming directory."""
    try:
        # Load configuration
        config = load_config()
        
        # Override config with CLI arguments
        if incoming_dir:
            config.notes_incoming_dir = incoming_dir
        if log_level:
            config.log_level = log_level
        
        # Setup logger
        logger = setup_logger("study_assistant", config.log_level)
        
        # Display banner
        console.print("\n[bold blue]📚 Study Assistant[/bold blue]\n", style="bold")
        
        # Process notes
        processor = NoteProcessor(config)
        results = processor.process_all_notes()
        
        if not results:
            console.print("[yellow]No new files to process[/yellow]")
        
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise typer.Exit(code=1)


@app.command()
def info() -> None:
    """Display configuration and system information."""
    try:
        config = load_config()
        
        console.print("\n[bold]Study Assistant Configuration[/bold]\n")
        console.print(f"Model: {config.openai_model}")
        console.print(f"Incoming Directory: {config.notes_incoming_dir}")
        console.print(f"Index Path: {config.processed_index_path}")
        console.print(f"Log Level: {config.log_level}\n")
        
    except Exception as e:
        console.print(f"[red]Error loading configuration:[/red] {e}")
        raise typer.Exit(code=1)
    
@app.command()
def watch() -> None:
    """Watch incoming directory and auto-process new notes."""
    try:
        from .auto_watcher import start_watching
        start_watching()
    except KeyboardInterrupt:
        console.print("\n[yellow]Stopped watching[/yellow]")
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise typer.Exit(code=1)


def main() -> None:
    """Entry point for the application."""
    app()


if __name__ == "__main__":
    main()
