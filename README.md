# TPS - TéléProcédure Simplifiée

## Context

TéléProcédure Simplifiée, ou TPS pour les intimes, est une plateforme 100% web et 0% email, conçue afin de répondre au besoin urgent de l'État d'appliquer la directive sur le 100% démat' à l'horizon 2018 pour les démarches administratives.


## Technologies utilisées

Ruby  : 2.3.1
Rails : 5.0.0.1


## Initialisation de l'environnement de développement

Afin d'initialiser l'environnement de développement, éxécutez la commande suivante :

    bundle install


## Création de la base de données

L'application utilise une base de donnée Postgresql. Pour en installer une, utilisez la commande suivante :

    sudo apt-get install postgresql

Les informations nécessaire à l'initialisation de la base doivent être pré-configurées à la main grâce à la procédure suivante :

    su - postgres
    psql
    > create user tps with password 'lol' createdb;
    > \q
    
    
Afin de générer la BDD de l'application, il est nécessaire d'éxécuter les commandes suivantes :

    rake db:create db:schema:load db:migrate
    rake db:create db:schema:load db:migrate RAILS_ENV=test


## Installation de Phantom JS

Installer PhantomJS qui est utilisé par les tests automatisés de l'application.


## Exécution des tests (Rspec)

Pour éxécuter les tests de l'application, plusieurs possibilités :

- Lancer tous les tests

        rake spec
        rspec

- Lancer un test en particulier

        rake spec SPEC=file_path/file_name_spec.rb:line_number
        rspec file_path/file_name_spec.rb:line_number

- Lancer tous les tests d'un fichier

        rake spec SPEC=file_path/file_name_spec.rb
        rspec file_path/file_name_spec.rb


## Regénérer les binstubs

    bundle binstub railties --force
    rake rails:update:bin