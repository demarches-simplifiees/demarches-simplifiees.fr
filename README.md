# demarches-simplifiees.fr

## Contexte

[demarches-simplifiees.fr](https://www.demarches-simplifiees.fr) est un site web conçu afin de répondre au besoin urgent de l'État d'appliquer la directive sur le 100 % dématérialisation pour les démarches administratives.

## Comment contribuer ?

demarches-simplifiees.fr est un [logiciel libre](https://fr.wikipedia.org/wiki/Logiciel_libre) sous licence AGPL.

Vous souhaitez y apporter des changements ou des améliorations ? Lisez notre [guide de contribution](CONTRIBUTING.md).

## Installation pour le développement

### Dépendances techniques

#### Tous environnements

- postgresql

#### Développement

- rbenv : voir https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts
- Yarn : voir https://yarnpkg.com/en/docs/install
- Overmind :
  * Mac : `brew install overmind`
  * Linux : voir https://github.com/DarthSim/overmind#installation

#### Tests

- Chrome
- chromedriver :
  * Mac : `brew install chromedriver`
  * Linux : voir https://sites.google.com/a/chromium.org/chromedriver/downloads

### Création des rôles de la base de données

Les informations nécessaire à l'initialisation de la base doivent être pré-configurées à la main grâce à la procédure suivante :

    su - postgres
    psql
    > create user tps_development with password 'tps_development' superuser;
    > create user tps_test with password 'tps_test' superuser;
    > \q

### Initialisation de l'environnement de développement

Afin d'initialiser l'environnement de développement, exécutez la commande suivante :

    bin/setup

### Lancement de l'application

    overmind start

L'application tourne à l'adresse `http://localhost:3000`. 

### Utilisateurs de test

En local, un utilisateur de test est créé automatiquement, avec les identifiants `test@exemple.fr`/`this is a very complicated password !`. (voir [db/seeds.rb](https://github.com/betagouv/tps/blob/dev/db/seeds.rb))

### Programmation des jobs

    AutoArchiveProcedureJob.set(cron: "* * * * *").perform_later
    WeeklyOverviewJob.set(cron: "0 8 * * 0").perform_later
    AutoReceiveDossiersForProcedureJob.set(cron: "* * * * *").perform_later(procedure_declaratoire_id, Dossier.states.fetch(:en_instruction))
    SendinblueUpdateAdministrateursJob.set(cron: "0 10 * * *").perform_later
    FindDubiousProceduresJob.set(cron: "0 0 * * *").perform_later
    Administrateurs::ActivateBeforeExpirationJob.set(cron: "0 8 * * *").perform_later
    WarnExpiringDossiersJob.set(cron: "0 0 1 * *").perform_later

### Voir les emails envoyés en local

Ouvrez la page [http://localhost:3000/letter_opener](http://localhost:3000/letter_opener).

### Mise à jour de l'application

Pour mettre à jour votre environnement de développement, installer les nouvelles dépendances et faire jouer les migrations, exécutez :

    bin/update

### Exécution des tests (RSpec)

Les tests ont besoin de leur propre base de données et certains d'entre eux utilisent Selenium pour s'exécuter dans un navigateur. N'oubliez pas de créer la base de test et d'installer chrome et chromedriver pour exécuter tous les tests.

Pour exécuter les tests de l'application, plusieurs possibilités :

- Lancer tous les tests

        bin/rake spec
        bin/rspec

- Lancer un test en particulier

        bin/rake spec SPEC=file_path/file_name_spec.rb:line_number
        bin/rspec file_path/file_name_spec.rb:line_number

- Lancer tous les tests d'un fichier

        bin/rake spec SPEC=file_path/file_name_spec.rb
        bin/rspec file_path/file_name_spec.rb

### Ajout de taches à exécuter au déploiement

        rails generate after_party:task task_name

### Debug

Une fois `overmind` lancé, et un breakpoint `byebug` inséré dans le code, il faut se connecter au process `server` dans un nouveau terminal afin d'intéragir avec byebug :

    overmind connect server

### Linting

Le projet utilise plusieurs linters pour vérifier la lisibilité et la qualité du code.

- Faire tourner tous les linters : `bin/rake lint`
- [AccessLint](http://accesslint.com/) tourne automatiquement sur les PRs

### Régénérer les binstubs

    bundle binstub railties --force
    bin/rake rails:update:bin

## Déploiement

- Tout nouveau commit ajouté à la branche `dev` est automatiquement déployé [en intégration](https://dev.demarches-simplifiees.fr/)
- Tout nouveau commit ajouté à la branche `master` est automatiquement déployé [en production](https://www.demarches-simplifiees.fr/)

## Tâches courantes

### Tâches de gestion des comptes super-admin

Des tâches de gestion des comptes super-admin sont prévues dans le namespace `superadmin`.
Pour les lister : `bin/rake -D superadmin:`.

### Tâches d’aide au support

Des tâches d’aide au support sont prévues dans le namespace `support`.
Pour les lister : `bin/rake -D support:`.

## Compatibilité navigateurs

L'application supporte les navigateurs récents : Firefox, Chrome, Safari, Edge et Internet Explorer 11 (voir `config/browser.rb`).

La compatibilité est testée par Browserstack.<br>[<img src="app/assets/images/browserstack-logo-600x315.png" width="200">](https://www.browserstack.com/)

## Performance

[![View performance data on Skylight](https://badges.skylight.io/status/zAvWTaqO0mu1.svg)](https://oss.skylight.io/app/applications/zAvWTaqO0mu1)

Nous utilisons Skylight pour suivre les performances de notre application.
