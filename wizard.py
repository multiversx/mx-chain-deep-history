
import logging
import subprocess
import sys
from argparse import ArgumentParser
from pathlib import Path
from typing import List

logger = logging.getLogger("wizard")

NETWORK_DEVNET = "devnet"
NETWORK_MAINNET = "mainnet"
NETWORKS = [NETWORK_DEVNET, NETWORK_MAINNET]

DEFAULT_ELROND_CONFIG_TAG = {
    NETWORK_DEVNET: "release-D1.3.46.0",
    NETWORK_MAINNET: "release-v1.3.46.0",
}

DEFAULT_ELROND_GO_TAG = {
    NETWORK_DEVNET: "v1.3.46",
    NETWORK_MAINNET: "v1.3.46",
}

SRC_IMPORT_DB = Path(__file__).parent.joinpath("import-db")
SRC_OBSERVERS = Path(__file__).parent.joinpath("observers")


def main(cli_args: List[str]):
    logging.basicConfig(level=logging.DEBUG)

    parser = ArgumentParser()
    parser.add_argument("--network", choices=NETWORKS, required=False)
    parsed_args = parser.parse_args(cli_args)
    network = parsed_args.network

    if not check_docker():
        return

    if not network:
        network = ask_choose_option("Pick a network!", NETWORKS)

    wizard_import_db(network)


def wizard_import_db(network: str):
    image_name = f"elrond-deep-history-import-db-{network}"

    tags = get_available_image_tags(image_name)
    if len(tags) == 0:
        image_tag = ask_input_string("Set an image tag", "latest")
        elrond_config_tag = ask_input_string(f"Tag / branch of elrond-config-{network}", DEFAULT_ELROND_CONFIG_TAG.get(network, ""))
        elrond_go_tag = ask_input_string(f"Tag / branch of elrond-go", DEFAULT_ELROND_GO_TAG.get(network, ""))
        build_image_import_db(network, image_tag, elrond_config_tag, elrond_go_tag)
    elif len(tags) == 1:
        image_tag = tags[0]
    else:
        image_tag = ask_choose_option(f"Pick a tag of the Docker image {image_name}:", tags)

    logger.info(f"network = {network}")
    logger.info(f"image_name = {image_name}")
    logger.info(f"image_tag = {image_tag}")


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


def ask_input_string(message: str, default: str) -> str:
    value = input(f"> {message} (default = {default}): ").strip()
    return value or default


def ask_choose_option(message: str, options: List[str]) -> str:
    print(message)

    for index, option in enumerate(options):
        print(f"{index}) {option}")

    option = int(input("> Option: "))
    return options[option]


def ask_confirm_continuation(message: str):
    print(message)
    answer = input("Continue? (y/n)")
    if answer.lower() not in ["y", "yes"]:
        print("Confirmation not given. Will stop.")
        exit(1)


def get_available_image_tags(image_name: str):
    args = ["docker", "images", image_name, "--format", "{{.Tag}}"]
    output = subprocess.check_output(args, universal_newlines=True)
    tags = output.splitlines()

    logger.debug(f"Tags of image {image_name}: {tags}")
    return tags


def build_image_import_db(network: str, image_tag: str, elrond_config_tag: str, elrond_go_tag: str):
    image_name = f"elrond-deep-history-import-db-{network}:{image_tag}"

    logger.info(f"build_image_import_db(): image_name = {image_name}")

    ask_confirm_continuation(f"The image {image_name} will be built locally. This make take a few minutes.")

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
