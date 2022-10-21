from typing import List


def ask_input_string(message: str, default: str = "") -> str:
    value = input(f"> {message} (default = {default}): ").strip()
    return value or default


def ask_input_strings(message: str, default: List[str]) -> List[str]:
    value = input(f"> {message} (default = {default}): ").strip()
    items = value.split(",")
    items = [item.strip() for item in items if item]
    items = [item for item in items if item]
    return items if items else default


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
