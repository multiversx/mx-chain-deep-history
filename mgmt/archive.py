import subprocess
import tarfile
from argparse import ArgumentParser
from pathlib import Path
from typing import List, Optional

from mgmt.constants import CHAIN_ID_BY_NETWORK, DOCKER_STOP_CONTAINER_PATIENCE
from mgmt.shared import ensure_folder, get_container_name, parse_epochs_arg


def main():
    parser = ArgumentParser()
    parser.add_argument("--data-folder", required=True)
    parser.add_argument("--archival-folder", required=True)
    parser.add_argument("--network", required=True)
    parser.add_argument("--epochs", required=False)
    parser.add_argument("--shards", action="append", required=True)
    parser.add_argument("--include-static", action="store_true", default=False)

    args = parser.parse_args()

    data_folder = Path(args.input_folder).expanduser()
    archival_folder = Path(args.archival_folder).expanduser()
    network = args.network
    epochs = parse_epochs_arg(args.epochs)
    include_static = args.include_static
    shards = list(args.shards)

    ensure_folder(archival_folder)

    print("Data folder:", data_folder)
    print("Archival folder:", archival_folder)
    print("Network:", network)
    print("Shards to archive:", shards)
    print("Epochs to archive:", epochs)
    print("Include 'Static':", include_static)

    for shard in shards:
        archive_shard(data_folder, archival_folder, network, shard, epochs, include_static)


def archive_shard(data_folder: Path, archival_folder: Path, network: str, shard: str, epochs: List[int], include_static: bool):
    input_folder = data_folder / network / "node-{shard}" / "db" / CHAIN_ID_BY_NETWORK[network]
    output_folder = archival_folder / network / "shard-{shard}"

    for epoch in epochs:
        archive_file = output_folder / f"Epoch_{epoch}.tar"
        relative_path = Path(f"Epoch_{epoch}") / f"Shard_{shard}"
        folder = input_folder / relative_path

        print("Archiving:", folder)

        tar = tarfile.open(archive_file, "w|")
        tar.add(folder, arcname=relative_path)
        tar.close()

    if include_static:
        print("Archiving folder 'Static' (with and without dblookup extensions)")

        archive_file = output_folder / "Static.tar"
        archive_file_min = output_folder / "Static.min.tar"
        folder = input_folder / "Static"

        # Create "Static.tar"
        tar = tarfile.open(archive_file, "w|")
        tar.add(folder, arcname="Static")
        tar.close()

        # Create "Static.min.tar"
        def min_filter(info: tarfile.TarInfo) -> Optional[tarfile.TarInfo]:
            return None if "DbLookupExtensions" in info.name else info

        tar = tarfile.open(archive_file_min, "w|")
        tar.add(folder, arcname="Static", filter=min_filter)
        tar.close()


def stop_observer(network: str, shard: str):
    container_name = get_container_name(network, shard)
    args = ["docker", "container", "stop", container_name, "--time", str(DOCKER_STOP_CONTAINER_PATIENCE)]
    subprocess.check_output(args, universal_newlines=True, stderr=subprocess.STDOUT)


def start_observer(network: str, shard: str):
    container_name = get_container_name(network, shard)
    args = ["docker", "container", "start", container_name]
    subprocess.check_output(args, universal_newlines=True, stderr=subprocess.STDOUT)


if __name__ == "__main__":
    main()
