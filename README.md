# Reusable Workflows with tbls
Contains workflows utilizing [tbls](https://github.com/k1Low/tbls) for database documentation and quality assurance with easy CI integration.

## ER Schema Documentation

Entity-relationship documentation is generated from Flyway migration files and published to [ris-reports](https://github.com/digitalservicebund/ris-reports).

For different database engines, there are different workflows.

### Generate documentation manually

1. Go to **Actions → Generate and Publish ER Documentation (PostgreSQL) → Run workflow**
2. Fill in the fields.
3. Click **Run workflow**. The result is generated and published to the S3 bucket, ready to use in [ris-reports](https://github.com/digitalservicebund/ris-reports).

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
    uses: digitalservicebund/tbls-workflows/.github/workflows/generate-er-docs-psql.yml@main
    with:
      source-repo: digitalservicebund/ris-backend-service
      source-ref: 3d0ec38eef7c8536b9d55ebf2de530f5465e5503
      database-name: caselaw
      migrations-path: backend/src/main/resources/db-scripts/migration
      destination-path: entity-relationship-diagrams-v2/ris-backend-service
      flyway-version: "10"
      postgres-version: "14"
      tbls-version: "1.94.5"
      local-artifact-path: "_tbls_generated"
    secrets: inherit
```

The `paths:` filter ensures the job only runs when migration files actually change.
`secrets: inherit` forwards the calling repo's secrets automatically - no extra configuration needed as long as both repos are public.

#### When is `GH_TOKEN` needed?

| Situation | `GH_TOKEN` needed? |
|---|---|
| Source repo is **public** | ✅ No - the built-in `GITHUB_TOKEN` is sufficient |
| Source repo is **private** | ⚠️ Yes - create a PAT with `repo` scope and store it as `GH_TOKEN` in repository secrets |
