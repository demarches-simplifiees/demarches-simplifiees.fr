# Procedures-Simplifiées Vagrant Linux

This vagrant file is here to create a vm on developer's machine dedicated to host Procédures-Simplifiées
(more doc on : https://fr.wikipedia.org/wiki/Vagrant)

If you are new to Vagrant, read the [Vagrant Getting Started](https://www.vagrantup.com/intro/getting-started/index.html)
which is quite quick to read and straightforward.

## Install VirtualBox

On your physical machine

```
sudo apt-add-repository "deb http://download.virtualbox.org/virtualbox/debian xenial contrib"
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
sudo apt-get update
sudo apt-get install virtualbox-5.2 dkms 
```

## Install Vagrant

On your host, you need to download vagrant on: https://www.vagrantup.com/downloads.html
(We don't use the ubuntu Vagrant package repo/ppa because of some changes on key. A PPA is to be done one day, see https://github.com/hashicorp/vagrant-installers/issues/12)

```
wget https://releases.hashicorp.com/vagrant/2.0.3/vagrant_2.0.3_x86_64.deb
sudo dpkg -i vagrant_2.0.3_x86_64.deb
```

Verify installation

```
vagrant
```

You should see:

```
 Usage: vagrant [options] <command> [<args>]

    -v, --version                    Print the version and exit.
    -h, --help                       Print this help.

 ...
```

## Launch the VM

From the directory containing the `Vagrantfile`, do:

```
vagrant up --provider=virtualbox
```

## Log into the VM

```
vagrant ssh
```

## Destroy the VM

```
vagrant destroy
```

