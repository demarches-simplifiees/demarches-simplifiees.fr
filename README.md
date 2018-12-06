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

L'application tourne à l'adresse `http://localhost:3000`. Un utilisateur de test est disponible, avec les identifiants `test@exemple.fr`/`testpassword`.

### Programmation des jobs

    AutoArchiveProcedureJob.set(cron: "* * * * *").perform_later
    WeeklyOverviewJob.set(cron: "0 8 * * 0").perform_later
    AutoReceiveDossiersForProcedureJob.set(cron: "* * * * *").perform_later(procedure_declaratoire_id, Dossier.states.fetch(:en_instruction))
    FindDubiousProceduresJob.set(cron: "0 0 * * *").perform_later
    Administrateurs::ActivateBeforeExpirationJob.set(cron: "0 8 * * *").perform_later
    WarnExpiringDossiersJob.set(cron: "0 0 1 * *").perform_later

### Voir les emails envoyés en local

Ouvrez la page [http://localhost:3000/letter_opener](http://localhost:3000/letter_opener).

### Mise à jour de l'application

Pour mettre à jour votre environnement de développement, installer les nouvelles dépendances et faire jouer les migrations, exécutez :

    bin/update

### Exécution des tests (RSpec)

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

Le projet utilise plusieurs linters pour vérifier la lisibilité et la qualité code.

- Faire tourner tous les linters : `bin/rake lint`
- [AccessLint](http://accesslint.com/) tourne automatiquement sur les PRs

### Régénérer les binstubs

    bundle binstub railties --force
    bin/rake rails:update:bin

## Déploiement

- Tout nouveau commit ajouté à la branche `dev` est automatiquement déployé [en intégration](https://dev.demarches-simplifiees.fr/)
- Tout nouveau commit ajouté à la branche `master` est automatiquement déployé [en production](https://www.demarches-simplifiees.fr/)

## Tâches courantes

### Tâches Super Admin

- ajouter un compte super admin :
  `bin/rake admin:create_admin[email-du-compte-github@exemple.com]`

- lister les comptes super admin :
  `bin/rake admin:list`

- supprimer un compte super admin :
  `bin/rake admin:delete_admin[email-du-compte-github@exemple.com]`

### Tâches d’aide au support

Des tâches d’aide au support sont prévues dans le namespace `support`.
Pour les lister : `bin/rake -D support:`.

## Compatibilité navigateurs

L'application supporte les navigateurs récents : Firefox, Chrome, Safari, Edge et Internet Explorer 11 (voir `config/browser.rb`).

La compatibilité est testée par Browserstack.<br>[<img src="app/assets/images/browserstack-logo-600x315.png" width="200">](https://www.browserstack.com/)

## Performance

[![View performance data on Skylight](https://badges.skylight.io/status/zAvWTaqO0mu1.svg)](https://oss.skylight.io/app/applications/zAvWTaqO0mu1)

Nous utilisons Skylight pour suivre les performances de notre application.
