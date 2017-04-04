# TPS - TéléProcédure Simplifiée

## Context

TéléProcédure Simplifiée, ou TPS pour les intimes, est une plateforme 100% web et 0% email, conçue afin de répondre au besoin urgent de l'État d'appliquer la directive sur le 100% démat' à l'horizon 2018 pour les démarches administratives.


## Dépendances

### Tous environnements

- postgresql

### Tests

- PhantomJS


## Initialisation de l'environnement de développement

Afin d'initialiser l'environnement de développement, éxécutez la commande suivante :

    bundle install


## Création de la base de données

Les informations nécessaire à l'initialisation de la base doivent être pré-configurées à la main grâce à la procédure suivante :

    su - postgres
    psql
    > create user tps_development with password 'tps_development' superuser;
    > create user tps_test with password 'tps_test' superuser;
    > \q

Afin de générer la BDD de l'application, il est nécessaire d'éxécuter les commandes suivantes :

    rake db:create db:schema:load db:migrate
    rake db:create db:schema:load db:migrate RAILS_ENV=test


## Exécution des tests (RSpec)

Pour exécuter les tests de l'application, plusieurs possibilités :

- Lancer tous les tests

        rake spec
        rspec

- Lancer un test en particulier

        rake spec SPEC=file_path/file_name_spec.rb:line_number
        rspec file_path/file_name_spec.rb:line_number

- Lancer tous les tests d'un fichier

        rake spec SPEC=file_path/file_name_spec.rb
        rspec file_path/file_name_spec.rb

## Linting

- Linter les fichiers HAML : `bundle exec haml-lint app/views/`

## Régénérer les binstubs

    bundle binstub railties --force
    rake rails:update:bin
