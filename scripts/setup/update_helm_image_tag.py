#!/usr/bin/env python3
import sys
from pathlib import Path

import yaml


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: update_helm_image_tag.py <values-file> <service-key> <image-tag>", file=sys.stderr)
        return 2

    values_path = Path(sys.argv[1])
    service_key = sys.argv[2]
    image_tag = sys.argv[3]

    if not values_path.exists():
        print(f"values file does not exist: {values_path}", file=sys.stderr)
        return 1

    data = yaml.safe_load(values_path.read_text()) or {}
    services = data.setdefault("services", {})
    service = services.setdefault(service_key, {})
    image = service.setdefault("image", {})
    image["tag"] = image_tag

    values_path.write_text(yaml.safe_dump(data, sort_keys=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
