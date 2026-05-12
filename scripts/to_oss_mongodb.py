#!/usr/bin/env python3
"""Convert a Grafana dashboard from grafana-mongodb-datasource (Grafana Cloud)
to haohanyang-mongodb-datasource (OSS) format.

Usage: python3 scripts/to_oss_mongodb.py < input.json > output.json
"""

import json
import re
import sys

CLOUD_PLUGIN = "grafana-mongodb-datasource"
OSS_PLUGIN = "haohanyang-mongodb-datasource"
OSS_DS_UID = "mongodb"
OSS_DS_NAME = "MongoDB"

SOURCE_URL_PREFIX = "https://github.com/petewall/dashboards/blob/main/marathon/"
TARGET_URL_PREFIX = "https://github.com/petewall/OpenSourceNorth-2026/blob/main/grafana/dashboards/Marathon/"

# Matches: database.collection.aggregate(pipeline)
AGGREGATE_RE = re.compile(r"^[^.]+\.([^.]+)\.aggregate\((.*)\)$", re.DOTALL)


def convert_query_spec(spec):
    m = AGGREGATE_RE.match(spec.get("query", ""))
    if not m:
        return spec
    return {
        "collection": m.group(1),
        "queryLanguage": "json",
        "queryText": m.group(2),
    }


def walk(obj):
    if isinstance(obj, dict):
        if obj.get("group") == CLOUD_PLUGIN:
            obj = {**obj, "group": OSS_PLUGIN}
            if "spec" in obj and "query" in obj["spec"]:
                obj = {**obj, "spec": convert_query_spec(obj["spec"])}
        if obj.get("pluginId") == CLOUD_PLUGIN:
            obj = {**obj, "pluginId": OSS_PLUGIN}
        if obj.get("name") == "datasource" and "current" in obj:
            obj = {**obj, "current": {"text": OSS_DS_NAME, "value": OSS_DS_UID}}
        if obj.get("type") == "link" and isinstance(obj.get("url"), str) and obj["url"].startswith(SOURCE_URL_PREFIX):
            obj = {**obj, "url": TARGET_URL_PREFIX + obj["url"][len(SOURCE_URL_PREFIX):]}
        return {k: walk(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [walk(item) for item in obj]
    return obj


if __name__ == "__main__":
    data = json.load(sys.stdin)
    json.dump(walk(data), sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
