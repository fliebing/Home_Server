Thought for a couple of seconds


Here’s a JSON Schema (draft-07) for your BOM.json and accompanying documentation explaining each top-level section and field.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "CycloneDX BOM 1.6 with Tagitek Extensions",
  "type": "object",
  "required": ["bomFormat", "specVersion", "serialNumber", "version", "metadata", "components", "dependencies"],
  "properties": {
    "bomFormat": {
      "type": "string",
      "const": "CycloneDX"
    },
    "specVersion": {
      "type": "string",
      "const": "1.6"
    },
    "serialNumber": {
      "type": "string",
      "format": "uuid",
      "description": "URN UUID of this BOM"
    },
    "version": {
      "type": "integer",
      "minimum": 1,
      "description": "BOM revision number"
    },
    "metadata": {
      "type": "object",
      "required": ["timestamp", "tools"],
      "properties": {
        "timestamp": {
          "type": "string",
          "format": "date-time",
          "description": "ISO-8601 UTC timestamp"
        },
        "tools": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["vendor", "name", "version"],
            "properties": {
              "vendor": { "type": "string" },
              "name": { "type": "string" },
              "version": { "type": "string" }
            }
          }
        }
      }
    },
    "components": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["type", "bom-ref", "name", "properties", "extensions"],
        "properties": {
          "type": {
            "type": "string",
            "enum": ["hardware", "virtual-machine", "container"],
            "description": "Component category"
          },
          "bom-ref": {
            "type": "string",
            "description": "Unique reference ID"
          },
          "name": { "type": "string" },
          "version": {
            "type": "string",
            "description": "OS/template or image version (optional for hardware)"
          },
          "properties": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["name", "value"],
              "properties": {
                "name": { "type": "string" },
                "value": { "type": "string" }
              }
            }
          },
          "extensions": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["extensionType", "roles", "ansiblePlaybook"],
              "properties": {
                "extensionType": { "type": "string", "const": "tagitek.config" },
                "roles": {
                  "type": "array",
                  "items": { "type": "string" }
                },
                "ansiblePlaybook": { "type": "string" },
                "env": {
                  "type": "object",
                  "additionalProperties": { "type": "string" }
                },
                "volumes": {
                  "type": "array",
                  "items": { "type": "string" }
                },
                "ports": {
                  "type": "array",
                  "items": { "type": "string", "pattern": "^\\d+/(tcp|udp)$" }
                },
                "schedules": {
                  "type": "object",
                  "properties": {
                    "backup": { "type": "string" },
                    "auto_backup_playbook": { "type": "string" }
                  },
                  "required": ["backup", "auto_backup_playbook"]
                },
                "n8nWorkflows": {
                  "type": "array",
                  "items": { "type": "string" }
                },
                "n8nNodes": {
                  "type": "array",
                  "items": { "type": "string" }
                }
              },
              "additionalProperties": false
            }
          }
        },
        "additionalProperties": false
      }
    },
    "dependencies": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["ref", "dependsOn"],
        "properties": {
          "ref": { "type": "string" },
          "dependsOn": {
            "type": "array",
            "items": { "type": "string" }
          }
        }
      }
    }
  },
  "additionalProperties": false
}
```

---

## Documentation

### 1. Top-level fields

* **bomFormat** (string, required)
  Must be `"CycloneDX"`.
* **specVersion** (string, required)
  Must be `"1.6"`.
* **serialNumber** (string, required, UUID format)
  A URN UUID identifying this BOM instance.
* **version** (integer, required)
  Revision number for this BOM.
* **metadata** (object, required)

  * **timestamp** (string, date-time)
    When this BOM was generated, in ISO-8601 UTC.
  * **tools** (array of objects)
    Which tool(s) generated or processed this BOM; each with:

    * **vendor**, **name**, **version** (all strings).

---

### 2. Components

An array of individual system pieces. Each component object has:

| Field            | Type      | Required? | Description                                                        |               |
| ---------------- | --------- | --------- | ------------------------------------------------------------------ | ------------- |
| **type**         | string    | yes       | One of `hardware`, `virtual-machine`, `container`.                 |               |
| **bom-ref**      | string    | yes       | Unique ID to reference in dependencies.                            |               |
| **name**         | string    | yes       | Hostname or container name.                                        |               |
| **version**      | string    | no        | OS template or image version (e.g., `Debian 12`, `MariaDB:10.11`). |               |
| **properties**   | array     | yes       | Key/value attributes like CPU, Memory, Network, etc.               |               |
| **extensions**   | array     | yes       | Tagitek custom config with:                                        |               |
|  extensionType   | string    | yes       | Always `tagitek.config`.                                           |               |
|  roles           | string\[] | yes       | Ansible roles applied.                                             |               |
|  ansiblePlaybook | string    | yes       | Path to Playbook.                                                  |               |
|  env             | object    | no        | Environment variables.                                             |               |
|  volumes         | string\[] | no        | Host\:container volume mappings.                                   |               |
|  ports           | string\[] | no        | Exposed ports, in \`"<port>/\<tcp                                  | udp>"\` form. |
|  schedules       | object    | no        | Cron schedule and backup playbook path.                            |               |
|  n8nWorkflows    | string\[] | no        | Paths to n8n workflow JSONs.                                       |               |
|  n8nNodes        | string\[] | no        | Paths to n8n node JSONs.                                           |               |

*Note*: only the fields actually present in your BOM need to be provided; others are optional and validated if present.

---

### 3. Dependencies

Defines build/run order:

```json
"dependencies": [
  { "ref": "<component-bom-ref>", "dependsOn": [ "<other-ref>", ... ] },
  …
]
```

* **ref** (string, required): a `bom-ref` from `components`.
* **dependsOn** (string\[], required): list of other `bom-ref`s that must exist or be configured first.

---

#### Example

```json
{ "ref": "vm-control-01", "dependsOn": ["hw-pve1"] }
```

means `control01.tagitek.com` relies on the physical host `hw-pve1` being available.

---

This schema and docs will ensure any future BOM you produce is validated, consistent, and self-describing, while still flexible enough to capture your Tagitek extensions.
