import os
from pathlib import Path
from typing import List


def get_container_name(network: str, shard: str):
    return f"deep-history-observer-{network}-{shard}"


def parse_epochs_arg(epochs_arg: str) -> List[int]:
    if not epochs_arg:
        return []

    # Handle specific epochs
    try:
        parts = epochs_arg.split(",")
        return [int(part) for part in parts]
    except Exception:
        pass

    # Handle ranges. E.g. 7:9.
    try:
        parts = epochs_arg.split(":")
        return list(range(int(parts[0]), int(parts[1]) + 1))
    except Exception:
        pass

    raise Exception(f"Cannot parse epochs: {epochs_arg}")


def ensure_folder(folder: Path):
    folder.mkdir(parents=True, exist_ok=True)


def list_archives(folder: Path) -> List[Path]:
    archives: List[Path] = [folder / file for file in os.listdir(folder)]
    archives = [file for file in archives if file.is_file() and file.suffix == ".tar"]
    archives.sort()
    return archives
