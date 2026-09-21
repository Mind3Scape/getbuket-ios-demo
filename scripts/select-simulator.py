#!/usr/bin/env python3
"""Select an available iPhone on this Mac; accept simctl JSON on stdin."""
import json
import os
import re
import sys


def select_device(data, requested=None):
    candidates = []
    for runtime, devices in data.get("devices", {}).items():
        match = re.search(r"\.iOS-(\d+)(?:-(\d+))?", runtime)
        if not match or int(match.group(1)) < 18:
            continue
        version = (int(match.group(1)), int(match.group(2) or 0))
        for device in devices:
            if device.get("isAvailable", False) and "iPhone" in device.get("name", ""):
                candidates.append((device, version))
    if requested:
        return next((d for d, _ in candidates if d["udid"] == requested), None)
    candidates.sort(key=lambda pair: (
        pair[0].get("state") == "Booted",
        pair[1],
        pair[0]["name"] == "iPhone 17 Pro",
        pair[0]["name"],
    ), reverse=True)
    return candidates[0][0] if candidates else None


if __name__ == "__main__":
    device = select_device(json.load(sys.stdin), os.environ.get("GETBUKET_DEVICE_ID"))
    if device:
        print(device["udid"])
    else:
        sys.exit(1)
