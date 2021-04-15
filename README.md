# Mes-Démarches.gov.pf

## Contexte

[Mes-Démarches](https://www.mes-demarches.gov.pf) est un site web conçu afin de répondre au besoin urgent de l'État et de la Polynésie Française d'appliquer la directive sur le 100 % dématérialisation pour les démarches administratives.

## Comment contribuer ?

Mes-Démarches est un fork (une copie tropicalisé) du site démarches-simplifiees.fr.
demarches-simplifiees.fr est un [logiciel libre](https://fr.wikipedia.org/wiki/Logiciel_libre) sous licence AGPL.

Vous souhaitez y apporter des changements ou des améliorations ? Lisez notre [guide de contribution](CONTRIBUTING.md).

## Installation pour le développement

### Dépendances techniques

#### Tous environnements

- postgresql

#### Développement

- rbenv : voir https://github.com/rbenv/rbenv-installer#rbenv-installer--doctor-scripts
- Yarn : voir https://yarnpkg.com/en/docs/install

#### Tests

- Chrome
- chromedriver :
  * Mac : `brew cask install chromedriver`
  * Linux : voir https://sites.google.com/a/chromium.org/chromedriver/downloads

### Création des rôles de la base de données

Les informations nécessaire à l'initialisation de la base doivent être pré-configurées à la main grâce à la procédure suivante :

    su - postgres
    psql
    > create user md with password 'md' superuser;
    > create user md_test with password 'md_test' superuser;
    > \q


### Initialisation de l'environnement de développement

Sous Ubuntu, certains packages doivent être installés au préalable :

    sudo apt-get install libcurl3 libcurl3-gnutls libcurl4-openssl-dev libcurl4-gnutls-dev zlib1g-dev libgeos-dev

Sous Mac, certains packages doivent être installés au préalable :

    brew install geos

Afin d'initialiser l'environnement de développement, exécutez la commande suivante :

    bin/setup

### Lancement de l'application

On lance le serveur d'application ainsi :

    bin/rails server

L'application tourne alors à l'adresse `http://localhost:3000`, et utilise le mécanisme par défaut de rails pour les tâches asynchrones.
C'est ce qu'on veut dans la plupart des cas. Une exception: ça ne joue pas les tâches cron.

Pour être une peu plus proche du comportement de production, et jouer les tâches cron, on peut lancer la message queue
dans un service dédié, et indiquer à rails d'utiliser delayed_job:

    bin/rake jobs:work
    RAILS_QUEUE_ADAPTER=delayed_job bin/rails server

### Utilisateurs de test

En local, un utilisateur de test est créé automatiquement, avec les identifiants `test@exemple.fr`/`this is a very complicated password !`. (voir [db/seeds.rb](https://github.com/betagouv/demarches-simplifiees.fr/blob/dev/db/seeds.rb))

### Programmation des tâches récurrentes

    rails jobs:schedule

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

### Linting

Le projet utilise plusieurs linters pour vérifier la lisibilité et la qualité du code.

- Faire tourner tous les linters : `bin/rake lint`
- Vérifier l'état des traductions : `bundle exec i18n-tasks health`
- [AccessLint](http://accesslint.com/) tourne automatiquement sur les PRs

### Régénérer les binstubs

    bundle binstub railties --force
    bin/rake rails:update:bin

## Déploiement

Dans le cas d’un déploiement sur plusieurs serveurs, l’application peut être déployée avec la tâche :

```
DOMAINS="web1 web2" BRANCH="main" bin/rake deploy
```

En interne, cette tâche utilise [mina](https://github.com/mina-deploy/mina) pour lancer les commandes
de déploiement sur tous les serveurs spécifiés.

## Tâches courantes

### Tâches de gestion des comptes super-admin

Des tâches de gestion des comptes super-admin sont prévues dans le namespace `superadmin`.
Pour les lister : `bin/rake -D superadmin:`.

### Tâches d’aide au support

Des tâches d’aide au support sont prévues dans le namespace `support`.
Pour les lister : `bin/rake -D support:`.

## Compatibilité navigateurs

L'application gère les navigateurs récents, parmis lequels Firefox, Chrome, Safari et Edge (voir `config/initializers/browser.rb`).

La compatibilité est testée par Browserstack.<br>[<img src="app/assets/images/browserstack-logo-600x315.png" width="200">](https://www.browserstack.com/)

## Performance

[![View performance data on Skylight](https://badges.skylight.io/status/zAvWTaqO0mu1.svg)](https://oss.skylight.io/app/applications/zAvWTaqO0mu1)

Nous utilisons Skylight pour suivre les performances de notre application.
