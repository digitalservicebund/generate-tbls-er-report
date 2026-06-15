# Reusable Workflows with tbls
Contains workflows utilizing [tbls](https://github.com/k1Low/tbls) for database documentation and quality assurance with easy CI integration.

## ER Schema Documentation

Entity-relationship documentation is generated from Flyway migration files and stored via [add-ris-report](https://github.com/digitalservicebund/add-ris-report).

For different database engines, there are different workflows.

### Trigger from another repo's workflow

Any repo can call this workflow automatically, e.g. on every push to `main`:

```yaml
name: Update ER Documentation

on:
  push:
    branches: [main]
    paths:
      - 'backend/src/main/resources/db-scripts/migration/**'

jobs:
  er-docs:
    uses: digitalservicebund/tbls-workflows/generate-er-docs-psql.yml@<SHA>
    with:
      # Required arguments:
      source-repo: digitalservicebund/ris-backend-service
      source-ref: 3d0ec38eef7c8536b9d55ebf2de530f5465e5503 # SHA, branch name, or tag
      database-name: "Caselaw Database"
      database-desc: "This database stores caselaw data and also has operative tables (e.g. for shedlock)."
      migrations-path: backend/src/main/resources/db-scripts/migration # Path to the migration scripts
      destination-path: entity-relationship-diagrams-v2/ris-backend-service # S3 Bucket
      # Optional, defaults can be overridden:
      flyway-version: "10"
      postgres-version: "14"
      tbls-version: "1.94.5"
      # tbls YAML config string (dsn, name, desc, and docPath are always injected)
      tbls-config: |
          format:
            adjust: true
          er:
            format: mermaid
      local-artifact-path: "_tbls_generated"
    secrets: inherit
```

The `paths:` filter ensures the job only runs when migration files actually change.
`secrets: inherit` forwards the calling repo's secrets automatically - no extra configuration needed as long as both repos are public.

### `local-artifact-path`

The workflow generates tbls output into a directory at the workspace root. The default is `_tbls_generated`. The entire contents of this directory are uploaded to the S3 bucket.

Change this if `_tbls_generated` is already used by something else in the source repo:

```yaml
    with:
      local-artifact-path: _tbls_er_output
```

### Secrets reference

The workflow requires two secrets for publishing and accepts one optional secret for private source repos.

#### `REPORTS_BUCKET_ACCESS_KEY_ID` and `REPORTS_BUCKET_SECRET_ACCESS_KEY` (required)

These credentials authorize uploads to the S3 bucket behind [add-ris-report](https://github.com/digitalservicebund/add-ris-report).
They must always be present - the publish step fails without them.

**How to pass them:**

- If the calling repo already has these secrets set (e.g. inherited from the organisation), use `secrets: inherit` and nothing else needs to be done.
- If not, pass them explicitly:

```yaml
    secrets:
      REPORTS_BUCKET_ACCESS_KEY_ID: ${{ secrets.REPORTS_BUCKET_ACCESS_KEY_ID }}
      REPORTS_BUCKET_SECRET_ACCESS_KEY: ${{ secrets.REPORTS_BUCKET_SECRET_ACCESS_KEY }}
```

#### `SLACK_BOT_TOKEN` (optional)

Used to connect to Slack when sending a notification on failure.
Failure notification is attempted when failure occurs and the parameter `slack-channel-id` is provided.

```yaml
    with:
      ...
      slack-channel-id: ${{ vars.SLACK_CHANNEL_ID }}
    secrets:
      SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
```

#### `GH_TOKEN` (optional)

Used to check out the source repository's migration files.

| Situation | What to do |
|---|---|
| Source repo is **public** | Omit `GH_TOKEN` - the built-in `GITHUB_TOKEN` is used automatically |
| Source repo is **private** | Create a PAT with `repo` scope, store it as a secret named `GH_TOKEN` in the calling repo, then pass it via `secrets: inherit` or explicitly: `GH_TOKEN: ${{ secrets.GH_TOKEN }}` |

#### Passing all secrets at once

The simplest approach when the calling repo is in the same organisation and already holds all required secrets:

```yaml
    secrets: inherit
```

Use explicit secret mapping instead when you want to be precise about which secrets are forwarded, or when secret names differ between repos.
