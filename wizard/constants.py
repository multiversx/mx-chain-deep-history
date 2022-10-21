from pathlib import Path

SHARDS = ["0", "1", "2", "metachain"]
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

SRC_IMPORT_DB = Path(__file__).parent.parent.joinpath("import-db")
SRC_OBSERVERS = Path(__file__).parent.parent.joinpath("observers")

ONE_MB = 1024 ** 2
