#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path

import yaml


def main() -> int:
    parser = argparse.ArgumentParser(description="Update Helm values image tag")
    parser.add_argument("--values-file", required=True, help="Path to values file")
    parser.add_argument("--service", required=True, help="Service name")
    parser.add_argument("--tag", required=True, help="Image tag")
    args = parser.parse_args()

    values_path = Path(args.values_file)
    service_key = args.service
    image_tag = args.tag

    # For medflow chart, services are nested under "services"
    # But let's handle the specific structure from values-dev.yaml
    # Strip "-service" suffix for the key if needed, or keep it.
    # The helm chart expects just "auth", "patient", etc.
    if service_key.endswith("-service"):
        helm_key = service_key[:-8]
    else:
        helm_key = service_key

    if not values_path.exists():
        print(f"values file does not exist: {values_path}", file=sys.stderr)
        return 1

    data = yaml.safe_load(values_path.read_text()) or {}
    services = data.setdefault("services", {})
    service = services.setdefault(helm_key, {})
    image = service.setdefault("image", {})
    image["tag"] = image_tag

    values_path.write_text(yaml.safe_dump(data, sort_keys=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
