#!/usr/bin/env python3
import argparse
import html
import json
import plistlib
import shutil
from datetime import datetime, timezone
from pathlib import Path
from string import Template

TEMPLATES = Path(__file__).resolve().parent.parent / "templates"


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Render manifest.plist, update.json and index.html for OTA distribution"
    )
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--ipa", required=True, type=Path)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--notes", type=Path)
    return parser.parse_args()


def render(template_name, values):
    template = Template((TEMPLATES / template_name).read_text())
    return template.substitute(values)


def main():
    arguments = parse_arguments()
    if not arguments.ipa.is_file():
        raise SystemExit(f"ipa not found: {arguments.ipa}")
    base_url = arguments.base_url.rstrip("/")
    ipa_name = f"{arguments.title}-{arguments.version}.ipa"
    notes = (
        arguments.notes.read_text().strip()
        if arguments.notes and arguments.notes.is_file()
        else ""
    )
    values = {
        "IPA_NAME": ipa_name,
        "IPA_URL": f"{base_url}/{ipa_name}",
        "MANIFEST_URL": f"{base_url}/manifest.plist",
        "PUBLISHED": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "NOTES_JSON": json.dumps(notes),
        "NOTES_HTML": html.escape(notes),
        "BUNDLE_ID": arguments.bundle_id,
        "VERSION": arguments.version,
        "BUILD_NUMBER": arguments.build,
        "TITLE": arguments.title,
    }

    out = arguments.out
    out.mkdir(parents=True, exist_ok=True)
    shutil.copy(arguments.ipa, out / ipa_name)
    manifest = render("manifest.plist.in", values)
    update = render("update.json.in", values)
    plistlib.loads(manifest.encode())
    json.loads(update)
    (out / "manifest.plist").write_text(manifest)
    (out / "update.json").write_text(update)
    (out / "index.html").write_text(render("index.html.in", values))
    for path in sorted(out.iterdir()):
        print(f"{path.stat().st_size:>10}  {path.name}")


if __name__ == "__main__":
    main()
