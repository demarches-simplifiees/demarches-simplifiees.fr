# Deployment documentation

demarches-simplifiees.fr is a standard Rails app, and can be deployed using standard methods (PaaS, Docker, bare-metal, etc.) Deployments are engineered not to require any downtime.

## 1. Deploying demarches-simplifiees.fr

Usually, a deployment goes like this (in pseudo-code):

```
# Run database schema migrations (e.g. `bin/rails db:migrate`)
# For each server:
  # Stop the server
  # Get the new code (e.g. `git clone https://github.com/demarches-simplifiees/demarches-simplifiees.fr.git`)
  # Install new dependencies (e.g. `bundle install && bun install`)
  # Restart the app server
# Run on deploy data migrations (e.g. `bundle exec deploy:maintenance_tasks`).
# Setup cron bundle `bundle exec rake jobs:schedule`
# Important: other maintenance tasks should be run manually after deployment, as soon as you can, from the UI at `https://yourserver.org/manager/maintenance_tasks`
```

## 2. Upgrading demarches-simplifiees.fr

### 2.1 Standard upgrade path

Theoretically, only deploying each version sequentially is fully supported. This means that to deploy the version N+3, the upgrade plan should be to deploy the version N+1, N+2 and then only N+3, in that order.

Release notes for each version are available on [GitHub's Releases page](https://github.com/demarches-simplifiees/demarches-simplifiees.fr/releases). Since 2022, when a release includes a database schema or data migration is present, this is mentionned in the release notes.

### 2.2 Upgrading several releases at once

Upgrading from several releases at once (like migrating directly from a version N to a version N+3) is theoretically unsupported. This is because database schema migrations and data migrations have to run in the exact order they were created, along the application code as it was when the migration was written.
That said, it is possible to batch the upgrade of several releases at once, _provided that the data migrations run in the correct order_.

The rule of thumb is that _an intermediary upgrade should be done before every database schema migration that follows a data migration_.

_NB: There are some plans to improve this, and contributions are welcome. See https://github.com/demarches-simplifiees/demarches-simplifiees.fr/issues/6970_
