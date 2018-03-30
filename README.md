# demarches-simplifiees.fr

## Context

demarches-simplifiees.fr est un site web conçue afin de répondre au besoin urgent de l'État d'appliquer la directive sur le 100 % dématérialisation pour les procédures administratives.


## Dépendances

### Tous environnements

- postgresql

### Développement

- Mailcatcher : `gem install mailcatcher`
- Overmind :
  * Mac : `brew install overmind`
  * Linux : voir https://github.com/DarthSim/overmind#installation

### Tests

- Chrome
- chromedriver :
  * Mac : `brew install chromedriver`
  * Linux : voir https://sites.google.com/a/chromium.org/chromedriver/downloads


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

    # Create and load the schema for both databases
    rake db:create db:schema:load

    # Migrate the development database and then the test database
    rake db:migrate
    rake db:migrate RAILS_ENV=test

## Bouchonnage de l’authentification

Créer le fichier `config/france_connect.yml` avec le contenu

```yaml
particulier_identifier: ''
particulier_secret: ''

particulier_redirect_uri: ''
particulier_authorization_endpoint: ''
particulier_token_endpoint: ''
particulier_userinfo_endpoint: ''
particulier_logout_endpoint: ''
```

Créer le fichier `config/github_secrets.yml` avec le contenu

```yaml
client_id: ''
client_secret: ''
```

## Connexion a Pipedrive

Dans le fichier `config/intializers/token.rb`, ajouter

`PIPEDRIVE_TOKEN = 'token'`

*Note : les valeurs pour ces paramètres sont renseignées dans le Keepass*

## Création des comptes initiaux

    rails c
    > email = "<votre email>"
    > password = "<votre mot de passe>"
    > Administration.create(email: email, password: password)
    > Administrateur.create(email: email, password: password)
    > Gestionnaire.create(email: email, password: password)
    > User.create(email: email, password: password)


## Lancement de l'application

    overmind s

## Programmation des jobs

    AutoArchiveProcedureJob.set(cron: "* * * * *").perform_later
    WeeklyOverviewJob.set(cron: "0 8 * * 0").perform_later
    AutoReceiveDossiersForProcedureJob.set(cron: "* * * * *").perform_later(procedure_declaratoire_id, 'en_instruction')
    FindDubiousProceduresJob.set(cron: "0 0 * * *").perform_later

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

## Debug

Une fois `overmind` lancé, et un breakpoint `byebug` inséré dans le code, il faut se connecter au process `server` dans un nouveau terminal afin d'intéragir avec byebug :

    overmind connect server

## Linting

- Faire tourner RuboCop : `bundle exec rubocop`
- Faire tourner Brakeman : `bundle exec brakeman`
- Linter les fichiers HAML : `bundle exec haml-lint app/views/`
- Linter les fichiers SCSS : `bundle exec scss-lint app/assets/stylesheets/`
- [AccessLint](http://accesslint.com/) tourne automatiquement sur les PRs

## Déploiement

- Tout nouveau commit ajouté à la branche `dev` est automatiquement déployé [en intégration](https://dev.demarches-simplifiees.fr/)
- Tout nouveau commit ajouté à la branche `master` est automatiquement déployé [en production](https://www.demarches-simplifiees.fr/)

## Régénérer les binstubs

    bundle binstub railties --force
    rake rails:update:bin

## Tâches Super Admin

- ajouter un compte super admin :
  `bundle exec rake admin:create_admin[email-du-compte-github@exemple.com]`

- lister les comptes super admin :
  `bundle exec rake admin:list`

- supprimer un compte super admin :
  `bundle exec rake admin:delete_admin[email-du-compte-github@exemple.com]`

## Compatibilité navigateurs

L'application supporte les navigateurs récents Firefox, Chrome, Internet Explorer (Edge, 11).

La compatibilité est testée par Browserstack.

[<img src="app/assets/images/browserstack-logo-600x315.png" width="300">](https://www.browserstack.com/)

## Performance

[![View performance data on Skylight](https://badges.skylight.io/status/zAvWTaqO0mu1.svg)](https://oss.skylight.io/app/applications/zAvWTaqO0mu1)

Nous utilisons Skylight pour suivre les performances de notre application.
