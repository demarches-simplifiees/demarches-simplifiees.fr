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

#### Tests

- Chrome
- chromedriver :
  * Mac : `brew install chromedriver`
  * Linux : voir https://sites.google.com/a/chromium.org/chromedriver/downloads

Si l'emplacement d'installation de Chrome n'est pas standard, ou que vous utilisez Brave ou Chromium à la place,
il peut être nécessaire d'overrider pour votre machine le path vers le binaire Chrome, par exemple :

```ruby
# create file spec/support/spec_config.local.rb

Selenium::WebDriver::Chrome.path = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"

# Must exactly match the browser version
Webdrivers::Chromedriver.required_version = "103.0.5060.53"
```

Il peut être également pertinent de désactiver la mise à jour automatique du webdriver
en définissant une variable d'environnement `SKIP_UPDATE_WEBDRIVER` lors de l'exécution de `bin/update`.

### Création des rôles de la base de données

Les informations nécessaire à l'initialisation de la base doivent être pré-configurées à la main grâce à la procédure suivante :

    su - postgres
    psql
    > create user tps_development with password 'tps_development' superuser;
    > create user tps_test with password 'tps_test' superuser;
    > \q


### Initialisation de l'environnement de développement

Sous Ubuntu, certains packages doivent être installés au préalable :

    sudo apt-get install libcurl3 libcurl3-gnutls libcurl4-openssl-dev libcurl4-gnutls-dev zlib1g-dev

Afin d'initialiser l'environnement de développement, exécutez la commande suivante :

    bin/setup

### Lancement de l'application

On lance le serveur d'application ainsi :

    bin/dev

L'application tourne alors à l'adresse `http://localhost:3000` avec en parallèle un worker pour les jobs et le bundler vitejs.

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

- Relancer uniquement les tests qui ont échoué précédemment

        bin/rspec --only-failures

- Lancer un ou des tests systèmes avec un browser

        NO_HEADLESS=1 bin/rspec spec/system

- Afficher les logs js en error issus de la console du navigateur `console.error('coucou')`

        JS_LOG=error bin/rspec spec/system

- Augmenter la latence lors de tests end2end pour déceler des bugs récalcitrants

        MAKE_IT_SLOW=1 bin/rspec spec/system

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

Voir les notes de déploiement dans [DEPLOYMENT.md](doc/DEPLOYMENT.md)

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

## Anonymisation des données

Si vous voulez configurer un rôle postgresql accédant à la base de données
anonymisée, installez [l’extension pg_anonymizer](https://postgresql-anonymizer.readthedocs.io/)
sur le serveur.

Le fonctionnement de pg\_anonymizer et de rails empêchent l’anonymisation à la volée
(dynamic masking) car le rôle (et le dump) voient des VIEW à la place des TABLE,
qui masquent des caractéristiques des nécessaires à Rails comme les séquences.

Le workflow général est le suivant :

- les règles d’anonymisation sont injectées (mises à jour) dans la base à chaque déploiement
- on exporte un dump classique de la base; il est réinjecté dans une base temporaire dans un environnement sécurisé
- on lance l’anonymisation statique sur cette base temporaire avec `anon.anonymize_database()`. Cela peut prendre plusieurs heures.
- on dump cette base anonymisée, qui peut être chiffré pour être transmise ailleurs.


### Détail

Créez le rôle qui supportera l’anonymisation.
(Adaptez avec le nom de rôle de votre choix, un mot de passe,
et le nom de la base en production).


```sql
CREATE ROLE pganonrole LOGIN PASSWORD 'password' IN ROLE tps_development;

\c tps_development
GRANT SELECT ON ALL TABLES IN SCHEMA public to pganonrole
```


Puis activez et configurez l’extension. Voici les étapes indicatives successives,
référez-vous à la documentation pour plus de détails.

```sql
CREATE EXTENSION IF NOT EXISTS anon CASCADE;

SELECT anon.init();

SECURITY LABEL FOR anon ON ROLE pganonrole IS 'MASKED';

ALTER DATABASE tps_development SET session_preload_libraries = 'anon';
# Il peut être nécessaire d'ouvrir une nouvelle session sql pour terminer la configuration.

NOTE: le salt doit être protégé avec le même niveau que les identifiants à la base de données.
ALTER DATABASE tps_development SET anon.salt = 'a-very-random-salty-string';
```

Enfin injectez les règles d’anonymisation :

```
rake anonymizer:setup_rules
```

Si les règles doivent évoluer, éditez-les dans le fichier. Cette tâche sera rejouée automatiquement
à chaque déploiement via un after party.


Pour lancer l’anonymisation et **réécrire toute la base** sur la base temporaire,
on se connecte avec le rôle anonymisé, puis :

```sql
anon.anonymize_database();
```
