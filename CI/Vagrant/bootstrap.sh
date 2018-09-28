#!/usr/bin/env bash

# Pre-requisites for further apt-get
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
sudo apt-get update

# DEPENDENCIES
# Global dependencies: Postgres, English language pack, git, gzip
# Dependencies for Overmind: tmux
# Dependencies for Ruby: autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev
#   zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev
# Dependencies for Mailcatcher: sqlite3 libsqlite3-dev
# Dependencies for Procédures-Simplifiées: libpq-dev libcurl3
sudo apt-get install -y \
    autoconf \
    bison \
    build-essential \
    git \
    gzip \
    language-pack-en-base \
    libcurl3 \
    libffi-dev \
    libgdbm3 \
    libgdbm-dev \
    libncurses5-dev \
    libpq-dev \
    libreadline6-dev \
    libsqlite3-dev \
    libssl-dev \
    libyaml-dev \
    postgresql \
    sqlite3 \
    tmux \
    zlib1g-dev

# NodeJS
# From https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs

# Yarn
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn

# Overmind
# From https://github.com/DarthSim/overmind#installation
curl -sL https://github.com/DarthSim/overmind/releases/download/v2.0.0.beta1/overmind-v2.0.0.beta1-linux-amd64.gz \
    -o overmind.gz
gunzip overmind.gz
chmod +x overmind
sudo mv overmind /usr/local/bin/

# SQL users
sudo -u postgres psql <<EOF
create user tps_development with password 'tps_development' superuser;
create user tps_test with password 'tps_test' superuser;
EOF

# Ruby 2.5.0 with rbenv
# From https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-16-04
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv install 2.5.0
rbenv global 2.5.0

# Rails
echo "gem: --no-document" > ~/.gemrc
gem install bundler rails
rbenv rehash

# Démarches-Simplifiées
git clone https://github.com/betagouv/tps.git
cd tps
bin/setup
