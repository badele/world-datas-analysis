#!/usr/bin/env python3

import re
import subprocess


def executeDuckdbQuery(query, mode="markdown"):
    command = f"duckdb db/wda.duckdb --{mode} '{query}'"

    process = subprocess.run(
        command,
        shell=True,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if process.returncode != 0:
        print(
            "###############################################################################"
        )
        print("# ERROR")
        print(
            "###############################################################################"
        )
        print("stderr:", process.stderr)

    return process.stdout


def update_providers():
    with open("README.md", "r", encoding="utf-8") as file:
        content = file.read()

    markdown = executeDuckdbQuery(
        "SELECT * FROM wda_providers ORDER BY provider",
    )

    new_content = re.sub(
        r"<!-- BEGIN PROVIDER -->.*<!-- END PROVIDER -->",
        f"<!-- BEGIN PROVIDER -->\n\n{markdown}\n<!-- END PROVIDER -->",
        content,
        flags=re.DOTALL,
    )

    with open("README.md", "w", encoding="utf-8") as file:
        file.write(new_content)


def update_scopesreference():
    with open("README.md", "r", encoding="utf-8") as file:
        content = file.read()

    markdown = executeDuckdbQuery(
        "SELECT * FROM wda_scopes_reference ORDER BY provider",
    )

    new_content = re.sub(
        r"<!-- BEGIN SCOPEREFERENCE -->.*<!-- END SCOPEREFERENCE -->",
        f"<!-- BEGIN SCOPEREFERENCE -->\n\n{markdown}\n<!-- END SCOPEREFERENCE -->",
        content,
        flags=re.DOTALL,
    )

    with open("README.md", "w", encoding="utf-8") as file:
        file.write(new_content)


def update_datasets():
    with open("README.md", "r", encoding="utf-8") as file:
        content = file.read()

    markdown = executeDuckdbQuery(
        "SELECT * FROM wda_datasets ORDER BY provider",
    )

    new_content = re.sub(
        r"<!-- BEGIN DATASET -->.*<!-- END DATASET -->",
        f"<!-- BEGIN DATASET -->\n\n{markdown}\n<!-- END DATASET -->",
        content,
        flags=re.DOTALL,
    )

    with open("README.md", "w", encoding="utf-8") as file:
        file.write(new_content)


def update_scopes():
    with open("README.md", "r", encoding="utf-8") as file:
        content = file.read()

    markdown = executeDuckdbQuery(
        "SELECT * FROM wda_scopes ORDER BY provider",
    )

    new_content = re.sub(
        r"<!-- BEGIN SCOPE -->.*<!-- END SCOPE -->",
        f"<!-- BEGIN SCOPE -->\n\n{markdown}\n<!-- END SCOPE -->",
        content,
        flags=re.DOTALL,
    )

    with open("README.md", "w", encoding="utf-8") as file:
        file.write(new_content)


if __name__ == "__main__":
    update_providers()
    update_datasets()
    update_scopesreference()
