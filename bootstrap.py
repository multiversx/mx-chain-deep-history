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

NETWORKS = ["devnet", "mainnet"]
SHARDS = ["0", "1", "2", "metachain"]


def main(cli_args: List[str]):
    logging.basicConfig(level=logging.DEBUG)

    parser = ArgumentParser()
    parser.add_argument("--workspace", required=True)
    parsed_args = parser.parse_args(cli_args)
    workspace = Path(parsed_args.workspace)
    downloads_folder = workspace / "downloads"
    downloads_folder.mkdir(parents=True, exist_ok=True)

    sketch_folders_structure(workspace)

    config_path = workspace / "reconstruction.json"
    with open(config_path) as f:
        config = json.load(f)

    networks: Dict[str, Any] = config.get("networks", dict())

    for network_key, network_value in networks.items():
        shards: Dict[str, Any] = network_value.get("shards", dict())

        for shard_key, shard_value in shards.items():
            logger.info(f"Setting up: network = {network_key}, shard = {shard_key}")

            node_folder = workspace / network_key / f"node-{shard_key}"
            db_folder = node_folder / "db"
            import_db_folder = node_folder / "import-db"

            db_is_empty = len(os.listdir(db_folder)) == 0
            db_import_is_empty = len(os.listdir(import_db_folder)) == 0

            if db_is_empty:
                oldest_archive_url = shard_value["oldestArchive"]
                oldest_archive_path = download_archive_if_missing(oldest_archive_url, downloads_folder, network_key, shard_key, "start")
                extract_archive(oldest_archive_path, db_folder.parent)
            else:
                logger.info(f"Skipping download & extraction, since folder isn't empty: {db_folder}")

            if db_import_is_empty:
                newest_archive_url = shard_value["newestArchive"]
                newest_archive_path = download_archive_if_missing(newest_archive_url, downloads_folder, network_key, shard_key, "target")
                extract_archive(newest_archive_path, import_db_folder)
            else:
                logger.info(f"Skipping download & extraction, since folder isn't empty: {import_db_folder}")


def sketch_folders_structure(workspace: Path):
    for network in NETWORKS:
        for shard in SHARDS:
            node_folder = workspace / network / f"node-{shard}"
            db_folder = node_folder / "db"
            import_db_folder = node_folder / "import-db"

            db_folder.mkdir(parents=True, exist_ok=True)
            import_db_folder.mkdir(parents=True, exist_ok=True)

            # TODO: For mx-chain-go v1.4.0 (upcoming), use the flag `--no-key` instead of using the keygenerator.
            generate_validator_key(node_folder)


def download_archive_if_missing(archive_url: str, downloads_folder: Path, network_key: str, shard_key: str, tag: str):
    logger.info(f"download_archive_if_missing(), url = {archive_url}")

    archive_extension = "".join(Path(archive_url).suffixes).strip(".")
    file_path = downloads_folder / f"{network_key}-{shard_key}-{tag}.{archive_extension}"
    temporary_file_path = downloads_folder / f"{file_path}.downloading"

    if file_path.exists():
        logger.info(f"File already exists, skipping download: file = {file_path}")
        return file_path

    subprocess.run(["wget", "-O", str(temporary_file_path), archive_url]).check_returncode()
    shutil.move(str(temporary_file_path), file_path)
    return file_path


def extract_archive(archive_path: Path, destination_folder: Path):
    logger.info(f"extract_archive(), archive = {archive_path}, destination = {destination_folder}")
    shutil.unpack_archive(archive_path, destination_folder)


def generate_validator_key(node_folder: Path):
    logger.info(f"generate_validator_key(), folder = {node_folder}")

    # TODO: For mx-chain-go v1.4.0 (upcoming), use the flag `--no-key` instead of generating keys.
    if not (node_folder / "validatorKey.pem").exists():
        subprocess.run(["/keygenerator"], cwd=node_folder).check_returncode()


if __name__ == "__main__":
    main(sys.argv[1:])
