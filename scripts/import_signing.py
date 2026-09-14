#!/usr/bin/env python3
import base64
import os
import plistlib
import secrets
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PROFILE_DIRECTORIES = [
    Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
    Path.home() / "Library/MobileDevice/Provisioning Profiles",
]


def security(*arguments, capture=False):
    return subprocess.run(
        ["security", *arguments], check=True, capture_output=capture, text=capture
    )


def required_environment(name):
    value = os.environ.get(name, "")
    if not value:
        sys.exit(f"{name} is empty")
    return value


def user_keychains():
    listing = security("list-keychains", "-d", "user", capture=True).stdout
    return [line.strip().strip('"') for line in listing.splitlines() if line.strip()]


def create_keychain(path, p12_path, p12_password):
    password = secrets.token_hex(16)
    security("create-keychain", "-p", password, str(path))
    security("set-keychain-settings", "-lut", "21600", str(path))
    security("unlock-keychain", "-p", password, str(path))
    security(
        "import",
        str(p12_path),
        "-k",
        str(path),
        "-P",
        p12_password,
        "-T",
        "/usr/bin/codesign",
        "-T",
        "/usr/bin/security",
        "-T",
        "/usr/bin/xcodebuild",
    )
    security(
        "set-key-partition-list",
        "-S",
        "apple-tool:,apple:,codesign:",
        "-s",
        "-k",
        password,
        str(path),
        capture=True,
    )
    security("list-keychains", "-d", "user", "-s", str(path), *user_keychains())


def install_profile(profile_path):
    decoded = security("cms", "-D", "-i", str(profile_path), capture=True).stdout
    profile = plistlib.loads(decoded.encode())
    for directory in PROFILE_DIRECTORIES:
        directory.mkdir(parents=True, exist_ok=True)
        shutil.copy(profile_path, directory / f"{profile['UUID']}.mobileprovision")
    return profile


def write_outputs(values):
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return
    with open(output_path, "a") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")


def main():
    p12_base64 = required_environment("P12_BASE64")
    p12_password = required_environment("P12_PASSWORD")
    profile_base64 = required_environment("PROFILE_BASE64")

    work = Path(tempfile.mkdtemp())
    keychain = work / "signing.keychain-db"
    p12_path = work / "signing.p12"
    profile_path = work / "profile.mobileprovision"
    p12_path.write_bytes(base64.b64decode(p12_base64))
    profile_path.write_bytes(base64.b64decode(profile_base64))
    create_keychain(keychain, p12_path, p12_password)
    p12_path.unlink()
    profile = install_profile(profile_path)

    security("find-identity", "-v", "-p", "codesigning", str(keychain))
    team_id = profile["TeamIdentifier"][0]
    print(f"profile: {profile['Name']} ({profile['UUID']}) team {team_id}")
    write_outputs(
        {"team_id": team_id, "profile_name": profile["Name"], "keychain": str(keychain)}
    )


if __name__ == "__main__":
    main()
