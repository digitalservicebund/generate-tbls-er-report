# Generate Entity Relationship Report with TBLS

Contains a [GitHub composite action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action) that use [tbls](https://github.com/k1Low/tbls) for database documentation and quality assurance with easy CI integration.

## Features

- 🗄️ Applies Flyway migrations against a throwaway PostgreSQL container
- 🔒 Isolated Docker network - no outbound internet during migration
- 📐 Generates Markdown docs and Mermaid ERDs via [tbls](https://github.com/k1low/tbls)
- ☁️ Publishes output to S3 via [add-ris-report](https://github.com/digitalservicebund/add-ris-report)
- 🔔 Optional Slack failure notifications

## Inputs

✅ Required &nbsp; 🔶 Conditionally required &nbsp; ❌ Not required

| Input | Description | Required | Default |
|---|---|:---:|---|
| `source_repo` | Source repository containing migration files (`org/repo`) | ✅ | |
| `source_ref` | Git ref to check out in the source repo (branch / tag / SHA - prefer a SHA) | ✅ | |
| `GH_TOKEN` | GitHub token for checking out private source repos. Action defaults to `GITHUB_TOKEN` if left empty. | ❌ | `""` |
| `database_name` | Name of the database (used as title in generated docs) | ✅ | |
| `database_desc` | Description of the database (shown in generated docs) | ✅ | |
| `migrations_path` | Path to the Flyway migration folder inside the source repo | ✅ | |
| `destination_path` | Destination path in the S3 bucket where artifacts are uploaded. Unused when `skip_publish` is `true`. | ✅ | |
| `BUCKET_ACCESS_KEY_ID` | S3 bucket access key ID | 🔶 | `""` |
| `BUCKET_SECRET_ACCESS_KEY` | S3 bucket secret access key | 🔶 | `""` |
| `skip_publish` | Set to `true` to skip the S3 upload step. When set, `BUCKET_ACCESS_KEY_ID` and `BUCKET_SECRET_ACCESS_KEY` are not required. | ❌ | `false` |
| `local_artifact_path` | Directory (relative to the source repo root) where tbls writes its output | ❌ | `_tbls_generated` |
| `flyway_version` | `flyway/flyway` Docker image tag | ❌ | `10` |
| `postgres_version` | `postgres` Docker image tag | ❌ | `14` |
| `tbls_version` | `k1low/tbls` Docker image tag | ❌ | `v1.94.5` |
| `tbls_config` | tbls YAML config string. `dsn`, `docPath`, `name`, and `desc` are always injected automatically. See [tbls_config](#tbls_config). | ❌ | Mermaid ERD |
| `slack_channel_id` | Slack channel ID for failure notifications. Requires `SLACK_BOT_TOKEN`. | ❌ | `""` |
| `SLACK_BOT_TOKEN` | Slack bot token used for failure notifications. | 🔶 | `""` |


## Usage

Add the action as a **step** inside any job that runs on `ubuntu-latest`:

```yaml
name: Update ER Documentation

on:
  push:
    branches: [main]
    paths:
      - 'backend/src/main/resources/db-scripts/migration/**'

jobs:
  er-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: digitalservicebund/generate-tbls-er-report@<SHA>
        with:
          source_repo: digitalservicebund/ris-backend-service
          source_ref: 3d0ec38eef7c8536b9d55ebf2de530f5465e5503  # prefer a SHA
          database_name: "Caselaw Database"
          database_desc: "Stores caselaw data."
          migrations_path: backend/src/main/resources/db-scripts/migration
          destination_path: entity-relationship-diagrams-v2/ris-backend-service
          BUCKET_ACCESS_KEY_ID: ${{ secrets.REPORTS_BUCKET_ACCESS_KEY_ID }}
          BUCKET_SECRET_ACCESS_KEY: ${{ secrets.REPORTS_BUCKET_SECRET_ACCESS_KEY }}
```

The `paths:` filter ensures the job only runs when migration files actually change.

> **Pin to a SHA** - unlike reusable workflows, composite actions do not support `@main` safely in production. Pin to a full commit SHA and update deliberately.

## How It Works

Entity-relationship documentation is generated from Flyway migration files and stored via [add-ris-report](https://github.com/digitalservicebund/add-ris-report). The migration is applied against an isolated PostgreSQL Docker container with no outbound internet connection.

### Credentials

Unlike reusable workflows, composite actions do not support a `secrets:` block - all credentials are passed as `with:` inputs. Sensitive inputs are masked automatically so they never appear in logs.

- **`BUCKET_ACCESS_KEY_ID` / `BUCKET_SECRET_ACCESS_KEY`** - authorize the S3 upload. Not needed when `skip_publish: true`.
- **`GH_TOKEN`** - only required for private source repos. Falls back to the built-in `GITHUB_TOKEN` when omitted.
- **`SLACK_BOT_TOKEN`** - enables failure notifications. Must be set together with `slack_channel_id`.

### `local_artifact_path`

tbls writes its output into a subdirectory of the checked-out source repo (default: `_tbls_generated`). The entire directory is then uploaded to S3. Change this if the default name conflicts with something in the source repo.

### `tbls_config`

The default config produces Mermaid ERDs with auto-adjusted layout. You can supply any valid [tbls YAML configuration](https://github.com/k1low/tbls?tab=readme-ov-file#configuration) via this input - the fields `dsn`, `docPath`, `name`, and `desc` are always injected automatically and will override any values you provide.
