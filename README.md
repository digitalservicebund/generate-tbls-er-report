# Generate Entity Relationship Report with TBLS

Contains a [GitHub composite action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action) that use [tbls](https://github.com/k1Low/tbls) for database documentation and quality assurance with easy CI integration.

## ER Schema Documentation

Entity-relationship documentation is generated from Flyway migration files and stored via [add-ris-report](https://github.com/digitalservicebund/add-ris-report). The migration is applied on a isolated PostgreSQL Docker container with no outbound internet connection.

### Usage (step level)

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
          # Required:
          source-repo: digitalservicebund/ris-backend-service
          source-ref: 3d0ec38eef7c8536b9d55ebf2de530f5465e5503  # prefer a SHA
          database-name: "Caselaw Database"
          database-desc: "Stores caselaw data."
          migrations-path: backend/src/main/resources/db-scripts/migration
          destination-path: entity-relationship-diagrams-v2/ris-backend-service
          bucket-access-key-id: ${{ secrets.REPORTS_BUCKET_ACCESS_KEY_ID }}
          bucket-secret-access-key: ${{ secrets.REPORTS_BUCKET_SECRET_ACCESS_KEY }}
          # Optional - override defaults or enable Slack notifications:
          flyway-version: "10"
          postgres-version: "14"
          tbls-version: "v1.94.5"
          tbls-config: |
            format:
              adjust: true
            er:
              format: mermaid
          local-artifact-path: "_tbls_generated"
          gh-token: ${{ secrets.GH_TOKEN }}
          slack-channel-id: ${{ vars.SLACK_CHANNEL_ID }}
          slack-bot-token: ${{ secrets.SLACK_BOT_TOKEN }}
```

The `paths:` filter ensures the job only runs when migration files actually change.

> **Pin to a SHA** - unlike reusable workflows, composite actions do not support `@main` safely in production. Pin to a full commit SHA and update deliberately.

### Inputs reference

#### Required

| Input | Description |
|---|---|
| `source-repo` | Source repository containing migration files (`org/repo`) |
| `source-ref` | Git ref to check out in the source repo (branch / tag / SHA - prefer a SHA) |
| `database-name` | Name of the database (used as title in generated docs) |
| `database-desc` | Description of the database (shown in generated docs) |
| `migrations-path` | Path to the Flyway migration folder inside the source repo |
| `destination-path` | Destination path in the S3 bucket where artifacts are uploaded |
| `bucket-access-key-id` | S3 bucket access key ID |
| `bucket-secret-access-key` | S3 bucket secret access key |

#### Optional

| Input | Default | Description |
|---|---|---|
| `flyway-version` | `10` | `flyway/flyway` Docker image tag |
| `postgres-version` | `14` | `postgres` Docker image tag |
| `tbls-version` | `v1.94.5` | `k1low/tbls` Docker image tag |
| `tbls-config` | mermaid ERD config (see below) | tbls YAML config string. `dsn`, `docPath`, `name`, and `desc` are always injected automatically. |
| `local-artifact-path` | `_tbls_generated` | Directory (relative to the source repo root) where tbls writes its output |
| `gh-token` | `""` (uses `GITHUB_TOKEN`) | GitHub token for checking out private source repos |
| `slack-channel-id` | `""` | Slack channel ID for failure notifications. Requires `slack-bot-token`. |
| `slack-bot-token` | `""` | Slack bot token used for failure notifications. |

### Credentials

Unlike reusable workflows, composite actions do not support a `secrets:` block. All credentials are passed as `with:` inputs.

#### `bucket-access-key-id` and `bucket-secret-access-key` (required)

These credentials authorize uploads to the S3 bucket behind [add-ris-report](https://github.com/digitalservicebund/add-ris-report).

```yaml
        with:
          bucket-access-key-id: ${{ secrets.REPORTS_BUCKET_ACCESS_KEY_ID }}
          bucket-secret-access-key: ${{ secrets.REPORTS_BUCKET_SECRET_ACCESS_KEY }}
```

#### `gh-token` (optional)

Used to check out the source repository's migration files.

| Situation | What to do |
|---|---|
| Source repo is **public** | Omit `gh-token` - the built-in `GITHUB_TOKEN` is used automatically |
| Source repo is **private** | Create a PAT with `repo` scope, store it as a secret, and pass it via `gh-token` |

```yaml
          gh-token: ${{ secrets.GH_TOKEN }}
```

#### `slack-bot-token` and `slack-channel-id` (optional)

Enables a Slack failure notification when a run fails on the default branch. Both inputs must be set together.

```yaml
          slack-channel-id: ${{ vars.SLACK_CHANNEL_ID }}
          slack-bot-token: ${{ secrets.SLACK_BOT_TOKEN }}
```

### `local-artifact-path`

The action generates tbls output into a directory inside the checked-out source repo. The default is `_tbls_generated`. The entire contents of this directory are uploaded to the S3 bucket.

Change this if `_tbls_generated` conflicts with something in the source repo:

```yaml
          local-artifact-path: _tbls_er_output
```

### `tbls-config`

The default config produces Mermaid ERDs with auto-adjusted layout:

```yaml
format:
  adjust: true
er:
  format: mermaid
```

You can supply any valid [tbls configuration](https://github.com/k1low/tbls?tab=readme-ov-file#configuration) as a YAML string. The fields `dsn`, `docPath`, `name`, and `desc` are always injected automatically and will override any values you provide for them.
