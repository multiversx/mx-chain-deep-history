import sys
from pathlib import Path

import requests

from wizard.constants import ONE_MB

CHUNK_SIZE = 1024 * 64
PROGRESS_RULER = "|_,_,_,_,_,,_,_,_,_,_|"

"""
Also see: https://github.com/ElrondNetwork/elrond-sdk-erdpy/blob/main/erdpy/downloader.py
"""


def download_file(url: str, filename: Path) -> None:
    print("Downloading:", url)

    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()

        total_size = int(response.headers.get("content-length", 0))
        total_size_mb = int(total_size / ONE_MB)
        chunk_number = 0
        progress = 0

        print(PROGRESS_RULER, f"{total_size_mb} MB", file=sys.stderr)
        print(" ", end="", file=sys.stderr)
        sys.stderr.flush()

        with open(filename, "wb") as file:
            for chunk in response.iter_content(chunk_size=CHUNK_SIZE):
                file.write(chunk)
                progress = _report_download_progress(progress, chunk_number, total_size)
                chunk_number += 1

        print("", file=sys.stderr)
        sys.stderr.flush()
    except requests.HTTPError as err:
        raise Exception(
            f"Could not download [{url}] to [{filename}]") from err


def _report_download_progress(progress: int, chunk_number: int, total_size: int):
    try:
        num_chunks = int(total_size / CHUNK_SIZE)
        new_progress = int((chunk_number / num_chunks) * 20)
        if new_progress > progress:
            progress_markers = "·" * (new_progress - progress)
            print(progress_markers, end='', file=sys.stderr)
        sys.stderr.flush()
        return new_progress
    except ZeroDivisionError:
        return 0
