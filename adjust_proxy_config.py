import sys
from argparse import ArgumentParser
from typing import Any, Dict, List

import toml


def main(cli_args: List[str]):
    parser = ArgumentParser()
    parser.add_argument("--file", required=True)
    parser.add_argument("--network")

    parsed_args = parser.parse_args(cli_args)
    file = parsed_args.file
    network = parsed_args.network
    data = toml.load(file)

    adjust_connected_observers(network, data)

    with open(file, "w") as f:
        toml.dump(data, f)

    print(f"Configuration adjusted: network = {network}, file = {file}")


def adjust_connected_observers(network: str, data: Dict[str, Any]):
    if network == "testnet":
        data["Observers"] = [
            {
                "ShardId": 0,
                "Address": "http://24.0.0.10:8080"
            },
            {
                "ShardId": 1,
                "Address": "http://24.0.0.11:8080"
            },
            {
                "ShardId": 2,
                "Address": "http://24.0.0.12:8080"
            },
            {
                "ShardId": 4294967295,
                "Address": "http://24.0.0.13:8080"
            },
        ]

        return

    if network == "devnet":
        data["Observers"] = [
            {
                "ShardId": 0,
                "Address": "http://23.0.0.10:8080"
            },
            {
                "ShardId": 1,
                "Address": "http://23.0.0.11:8080"
            },
            {
                "ShardId": 2,
                "Address": "http://23.0.0.12:8080"
            },
            {
                "ShardId": 4294967295,
                "Address": "http://23.0.0.13:8080"
            },
        ]

        return

    if network == "mainnet":
        data["Observers"] = [
            {
                "ShardId": 0,
                "Address": "http://22.0.0.10:8080"
            },
            {
                "ShardId": 1,
                "Address": "http://22.0.0.11:8080"
            },
            {
                "ShardId": 2,
                "Address": "http://22.0.0.12:8080"
            },
            {
                "ShardId": 4294967295,
                "Address": "http://22.0.0.13:8080"
            },
        ]

        return

    raise Exception(f"Unknown network: {network}")


if __name__ == "__main__":
    main(sys.argv[1:])
