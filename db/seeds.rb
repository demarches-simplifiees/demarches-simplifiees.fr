# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Dir[File.join(Rails.root, 'db', 'seeds', '*.rb')].sort.each { |seed| load seed }

#SEEDS DEV, TEST
User.create({
    email: 'test@localhost.com',
    password: 'password'
})

@dossier = Dossier.create({
    id: 10000,
    nom_projet: 'Projet de test',
    description: 'Description de test.',
    montant_projet: 12000,
    montant_aide_demande: 3000,
    date_previsionnelle: '20/01/2016',
    mail_contact: 'test@test.com',
    ref_formulaire: '12'
})

@entreprise = Entreprise.create({id: 10000, siren: 431449040, date_creation: 1437665347, dossier: @dossier, raison_sociale: 'Coucou', code_effectif_entreprise: '00'})
@etablissement = Etablissement.create({id: 10000, siret: 43144904000028, siege_social: true, adresse: '50 avenue des champs élysées Paris 75008', entreprise: @entreprise, dossier: @dossier})


Commentaire.create({email: 'test@test.com', body: 'Commentaire de test', dossier: @dossier})