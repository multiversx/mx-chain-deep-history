

import json
import logging
import os
import shutil
import subprocess
import sys
from argparse import ArgumentParser
from pathlib import Path
from typing import Any, Dict, List

logger = logging.getLogger("bootstrap")


def main(cli_args: List[str]):
    logging.basicConfig(level=logging.DEBUG)

    parser = ArgumentParser()
    parser.add_argument("--workspace", required=True)
    parsed_args = parser.parse_args(cli_args)
    workspace = Path(parsed_args.workspace)
    downloads_folder = workspace / "downloads"
    downloads_folder.mkdir(parents=True, exist_ok=True)

    config_path = workspace / "reconstruction.json"
    with open(config_path) as f:
        config = json.load(f)

    networks: Dict[str, Any] = config.get("networks", dict())

    for network_key, network_value in networks.items():
        shards: Dict[str, Any] = network_value.get("shards", dict())

        for shard_key, shard_value in shards.items():
            db_folder = workspace / network_key / f"node-{shard_key}" / "db"
            import_db_folder = workspace / network_key / f"node-{shard_key}" / "import-db"

            db_folder.mkdir(parents=True, exist_ok=True)
            import_db_folder.mkdir(parents=True, exist_ok=True)

            oldest_archive_url = shard_value.get("oldestArchive", "")
            newest_archive_url = shard_value.get("newestArchive", "")

            oldest_archive_extension = "".join(Path(oldest_archive_url).suffixes).strip(".")
            newest_archive_extension = "".join(Path(oldest_archive_url).suffixes).strip(".")

            oldest_file_path = downloads_folder / f"{network_key}-{shard_key}-oldest.{oldest_archive_extension}"
            newest_file_path = downloads_folder / f"{network_key}-{shard_key}-newest.{newest_archive_extension}"
            temporary_file_path = downloads_folder / "downloading.archive"

            if oldest_archive_url and not oldest_file_path.exists():
                subprocess.run(["wget", "-O", str(temporary_file_path), oldest_archive_url]).check_returncode()
                shutil.move(str(temporary_file_path), oldest_file_path)
            if newest_archive_url and not newest_file_path.exists():
                subprocess.run(["wget", "-O", str(temporary_file_path), newest_archive_url]).check_returncode()
                shutil.move(str(temporary_file_path), newest_file_path)

            if len(os.listdir(db_folder)) > 0:
                raise Exception(f"Folder isn't empty: {db_folder}")
            if len(os.listdir(import_db_folder)) > 0:
                raise Exception(f"Folder isn't empty: {import_db_folder}")

            shutil.unpack_archive(oldest_file_path, db_folder.parent)
            shutil.unpack_archive(newest_file_path, import_db_folder)


if __name__ == "__main__":
    main(sys.argv[1:])
