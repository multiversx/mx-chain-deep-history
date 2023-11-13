import sys
from argparse import ArgumentParser
from pathlib import Path
from typing import List

"""
python3 adjust_observer_src.py --src=...
"""


def main(cli_args: List[str]):
    parser = ArgumentParser()
    parser.add_argument("--src", type=Path, required=True)
    parser.add_argument("--max-headers-to-request-in-advance", type=int, default=20)

    parsed_args = parser.parse_args(cli_args)
    src = parsed_args.src
    max_headers_to_request_in_advance = parsed_args.max_headers_to_request_in_advance

    replace_line_in_file(src / "process" / "constants.go", "const MaxHeadersToRequestInAdvance = 20", f"const MaxHeadersToRequestInAdvance = {max_headers_to_request_in_advance}")


def replace_line_in_file(file: Path, old: str, new: str):
    lines_input = file.read_text().splitlines()
    lines_output: List[str] = []

    if old not in lines_input:
        raise Exception(f"Line not found in {file}: {old}")

    for line in lines_input:
        if line == old:
            lines_output.append(new)
        else:
            lines_output.append(line)

    file.write_text("\n".join(lines_output) + "\n")


if __name__ == "__main__":
    main(sys.argv[1:])
