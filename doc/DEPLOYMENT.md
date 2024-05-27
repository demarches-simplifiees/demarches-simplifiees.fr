# Deployment documentation

demarches-simplifiees.fr is a standard Rails app, and can be deployed using standard methods (PaaS, Docker, bare-metal, etc.) Deployments are engineered not to require any downtime.

## 1. Deploying demarches-simplifiees.fr

Usually, a deployment goes like this (in pseudo-code):

```
# Run database schema migrations (e.g. `bin/rails db:migrate`)
# For each server:
  # Stop the server
  # Get the new code (e.g. `git clone git@github.com:betagouv/demarches-simplifiees.fr.git`)
  # Install new dependencies (e.g. `bundle install && bun install`)
  # Restart the app server
# Run data migrations (e.g. `rake after_party:run`)
```

On the main instance, this deployment flow is implemented using [`mina`](https://github.com/mina-deploy/mina), which automatically sshs to the application servers, run the appropriate commands (see `lib/tasks/deploy.rake` and `config/deploy.rb`), and restarts the puma webserver in a way that ensures zero-downtime deployments.
A deploy on multiple application servers is typically done using:
```shell
DOMAINS="web1 web2" BRANCH="main" bin/rake deploy
```

But of course other methods can be used.

## 2. Upgrading demarches-simplifiees.fr

### 2.1 Standard upgrade path

Theoretically, only deploying each version sequentially is fully supported. This means that to deploy the version N+3, the upgrade plan should be to deploy the version N+1, N+2 and then only N+3, in that order.

Release notes for each version are available on [GitHub's Releases page](https://github.com/betagouv/demarches-simplifiees.fr/releases). Since 2022, when a release includes a database schema or data migration is present, this is mentionned in the release notes.

### 2.2 Upgrading several releases at once

Upgrading from several releases at once (like migrating directly from a version N to a version N+3) is theoretically unsupported. This is because database schema migrations and data migrations have to run in the exact order they were created, along the application code as it was when the migration was written.
That said, it is possible to batch the upgrade of several releases at once, _provided that the data migrations run in the correct order_.

The rule of thumb is that _an intermediary upgrade should be done before every database schema migration that follows a data migration_.

_NB: There are some plans to improve this, and contributions are welcome. See https://github.com/betagouv/demarches-simplifiees.fr/issues/6970_

# Historical notes

- During 2021, some older data migration tasks were deleted from the repository. This has to be checked manually when upgrading from an older version.
  ```
  lib/tasks/deployment/20200326133630_cleanup_deleted_dossiers.rake                       
  lib/tasks/deployment/20200401123317_process_expired_dossiers_en_construction.rake                      
  lib/tasks/deployment/20200527124112_fix_champ_etablissement.rake                 
  lib/tasks/deployment/20200528124044_fix_dossier_etablissement.rake                   
  lib/tasks/deployment/20200618121241_drop_down_list_options_to_json.rake                      
  lib/tasks/deployment/20200625113026_migrate_revisions.rake                         
  lib/tasks/deployment/20200630154829_add_traitements_from_dossiers.rake                          
  lib/tasks/deployment/20200708101123_add_default_skip_validation_to_piece_justificative.rake                        
  lib/tasks/deployment/20200728150458_fix_cloned_revisions.rake                            
  lib/tasks/deployment/20200813111957_fix_geo_areas_geometry.rake      
  lib/tasks/deployment/20201001161931_migrate_filters_to_use_stable_id.rake            
  lib/tasks/deployment/20201006123842_setup_first_stats.rake                                           
  lib/tasks/deployment/20201218163035_fix_types_de_champ_revisions.rake                             
  ```
