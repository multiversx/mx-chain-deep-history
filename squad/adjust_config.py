import sys
from argparse import ArgumentParser
from typing import List

import toml

"""
python3 ./adjust_config.py --mode=main --file=/go/elrond-config-devnet/config.toml
python3 ./adjust_config.py --mode=prefs --file=/go/elrond-config-devnet/prefs.toml
python3 ./adjust_config.py --mode=proxy --file=/go/elrond-proxy-go/cmd/proxy/config/config.toml
"""

MODE_MAIN = "main"
MODE_PREFS = "prefs"
MODE_PROXY = "proxy"
MODES = [MODE_MAIN, MODE_PREFS, MODE_PROXY]


def main(cli_args: List[str]):
    parser = ArgumentParser()
    parser.add_argument("--mode", choices=MODES, required=True)
    parser.add_argument("--file", required=True)
    parser.add_argument("--network")
    parser.add_argument("--api-simultaneous-requests", type=int, default=256)
    parser.add_argument("--api-trie-operations-timeout", type=int, default=60000)

    parsed_args = parser.parse_args(cli_args)
    mode = parsed_args.mode
    file = parsed_args.file
    network = parsed_args.network
    api_simultaneous_requests = parsed_args.api_simultaneous_requests
    api_trie_operations_timeout = parsed_args.api_trie_operations_timeout

    data = toml.load(file)

    if mode == MODE_MAIN:
        data["GeneralSettings"]["StartInEpochEnabled"] = False
        data["DbLookupExtensions"]["Enabled"] = True
        data["StateTriesConfig"]["AccountsStatePruningEnabled"] = False
        data["StoragePruning"]["ObserverCleanOldEpochsData"] = False
        data["StoragePruning"]["AccountsTrieCleanOldEpochsData"] = False
        data["Antiflood"]["WebServer"]["SimultaneousRequests"] = api_simultaneous_requests
        data["Antiflood"]["WebServer"]["TrieOperationsDeadlineMilliseconds"] = api_trie_operations_timeout
    elif mode == MODE_PREFS:
        data["Preferences"]["FullArchive"] = True
    elif mode == MODE_PROXY:
        if network == "devnet":
            data["Observers"] = [
                {
                    "ShardId": 0,
                    "Address": "http://12.0.0.20:8080"
                },
                {
                    "ShardId": 1,
                    "Address": "http://12.0.0.21:8080"
                },
                {
                    "ShardId": 2,
                    "Address": "http://12.0.0.22:8080"
                },
                {
                    "ShardId": 4294967295,
                    "Address": "http://12.0.0.23:8080"
                },
            ]
        elif network == "mainnet":
            data["Observers"] = [
                {
                    "ShardId": 0,
                    "Address": "http://12.0.0.10:8080"
                },
                {
                    "ShardId": 1,
                    "Address": "http://12.0.0.11:8080"
                },
                {
                    "ShardId": 2,
                    "Address": "http://12.0.0.12:8080"
                },
                {
                    "ShardId": 4294967295,
                    "Address": "http://12.0.0.13:8080"
                },
            ]
        else:
            raise Exception(f"Unknown network: {network}")
    else:
        raise Exception(f"Unknown mode: {mode}")

    with open(file, "w") as f:
        toml.dump(data, f)

    print(f"Configuration adjusted: mode = {mode}, file = {file}")


if __name__ == "__main__":
    main(sys.argv[1:])
