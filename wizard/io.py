from pathlib import Path


def get_downloads_path(workspace: Path):
    return workspace / "downloads"


def get_node_import_db_path(workspace: Path, network: str, shard: str) -> Path:
    return workspace / network / f"node-{shard}" / "import-db"
