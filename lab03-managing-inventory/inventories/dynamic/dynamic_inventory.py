#!/usr/bin/env python3
"""A tiny dynamic inventory script.

Ansible runs the script with --list (and sometimes --host NAME) and reads JSON
from its output. A real script would ask a cloud API or CMDB which servers
exist; this one returns a fixed answer so you can see the format.
"""
import argparse
import json

INVENTORY = {
    "webservers": {"hosts": ["app-node-1", "app-node-2"], "vars": {"http_port": 8080}},
    "databases": {"hosts": ["db-node-1"]},
    "_meta": {
        "hostvars": {
            "app-node-1": {"ansible_host": "10.0.1.10"},
            "app-node-2": {"ansible_host": "10.0.1.11"},
            "db-node-1": {"ansible_host": "10.0.2.10"},
        }
    },
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--host")
    args = parser.parse_args()

    if args.host:
        # Variables for one host (Ansible skips this call when _meta is present)
        print(json.dumps(INVENTORY["_meta"]["hostvars"].get(args.host, {}), indent=2))
    else:
        print(json.dumps(INVENTORY, indent=2))


if __name__ == "__main__":
    main()
