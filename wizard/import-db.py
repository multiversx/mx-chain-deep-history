import logging
import subprocess
import sys
from argparse import ArgumentParser
from pathlib import Path
from typing import List

from wizard import io, ux
from wizard.archives import ImportDbArchivesController
from wizard.constants import (DEFAULT_ELROND_CONFIG_TAG, DEFAULT_ELROND_GO_TAG,
                              NETWORKS, SHARDS, SRC_IMPORT_DB)

logger = logging.getLogger("wizard")


def main(cli_args: List[str]):
    logging.basicConfig(level=logging.DEBUG)

    parser = ArgumentParser()
    parser.add_argument("--network", choices=NETWORKS, required=False)
    parser.add_argument("--shards", nargs="+", required=False)
    parser.add_argument("--num-parallel-downloads", type=int, default=2)
    parsed_args = parser.parse_args(cli_args)
    network: str = parsed_args.network
    shards: List[str] = parsed_args.shards
    num_parallel_downloads = parsed_args.num_parallel_downloads

    if not check_docker():
        return

    if not network:
        network = ux.ask_choose_option("Pick a network!", NETWORKS)

    if not shards:
        shards = ux.ask_input_strings("Which shards (CSV)?", SHARDS)

    wizard_import_db(network, shards, num_parallel_downloads)


def wizard_import_db(network: str, shards: List[str], num_parallel_downloads: int):
    image_name = f"elrond-deep-history-import-db-{network}"

    tags = get_available_image_tags(image_name)
    if len(tags) == 0:
        image_tag = ux.ask_input_string("Set an image tag", "latest")
        elrond_config_tag = ux.ask_input_string(f"Tag / branch of elrond-config-{network}", DEFAULT_ELROND_CONFIG_TAG.get(network, ""))
        elrond_go_tag = ux.ask_input_string(f"Tag / branch of elrond-go", DEFAULT_ELROND_GO_TAG.get(network, ""))
        build_image_import_db(network, image_tag, elrond_config_tag, elrond_go_tag)
    elif len(tags) == 1:
        image_tag = tags[0]
    else:
        image_tag = ux.ask_choose_option(f"Pick a tag of the Docker image {image_name}:", tags)

    workspace = Path(ux.ask_input_string("Set a workspace", str(Path.home() / "deep-history-workspace")))

    for shard in shards:
        io.get_node_import_db_path(workspace, network, shard).mkdir(parents=True, exist_ok=True)
        io.get_node_db_path(workspace, network, shard).mkdir(parents=True, exist_ok=True)

    archives_controller = ImportDbArchivesController(workspace, network, shards, num_parallel_downloads)
    archives_controller.download()


def check_docker():
    logger.info("check_docker()")

    try:
        subprocess.run(["docker", "--version"]).check_returncode()
        logger.info("Docker is installed.")
    except:
        logger.error("Please install Docker.")
        return False

    try:
        subprocess.run(["docker", "compose", "version"]).check_returncode()
        logger.info("Docker Compose is installed.")
    except:
        logger.error("Please install Docker Compose.")
        return False

    return True


def get_available_image_tags(image_name: str):
    args = ["docker", "images", image_name, "--format", "{{.Tag}}"]
    output = subprocess.check_output(args, universal_newlines=True)
    tags = output.splitlines()

    logger.debug(f"Tags of image {image_name}: {tags}")
    return tags


def build_image_import_db(network: str, image_tag: str, elrond_config_tag: str, elrond_go_tag: str):
    image_name = f"elrond-deep-history-import-db-{network}:{image_tag}"

    logger.info(f"build_image_import_db(): image_name = {image_name}")

    ux.ask_confirm_continuation(f"The image {image_name} will be built locally. This make take a few minutes.")

    args = [
        "docker", "image", "build",
        "--build-arg", f"ELROND_CONFIG_NAME=elrond-config-{network}",
        "--build-arg", f"ELROND_CONFIG_TAG={elrond_config_tag}",
        "--build-arg", f"ELROND_GO_TAG={elrond_go_tag}",
        "--no-cache", SRC_IMPORT_DB,
        "-t", image_name,
        "-f", SRC_IMPORT_DB / "Dockerfile"
    ]

    return_code = subprocess.run(args).returncode
    if return_code != 0:
        raise Exception(f"Cannot build Docker image, return code = {return_code}")


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except Exception as e:
        print("Error:", e)
