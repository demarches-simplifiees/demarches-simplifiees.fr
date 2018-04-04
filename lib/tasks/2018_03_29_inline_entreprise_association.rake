namespace :'2018_03_29_inline_entreprise_association' do
  task fix_date_fin_exercice: :environment do
    Exercice.where(date_fin_exercice: nil).find_each do |exercice|
      exercice.update_column(:date_fin_exercice, exercice.dateFinExercice)
    end
  end

  task fix_missing_entreprise: :environment do
    Etablissement.includes(:entreprise).where(entreprise_siren: nil).find_each do |etablissement|
      dossier_id = etablissement.dossier_id

      if !etablissement.entreprise
        etablissement.entreprise = Dossier.find_by(id: dossier_id)&.entreprise
      end

      etablissement.save
    end
  end

  task inline_entreprise_association: :environment do
    Etablissement.includes(entreprise: :rna_information, exercices: []).where(entreprise_siren: nil).find_each do |etablissement|
      entreprise = etablissement.entreprise

      if entreprise
        etablissement.entreprise_siren = entreprise.siren
        etablissement.entreprise_capital_social = entreprise.capital_social
        etablissement.entreprise_numero_tva_intracommunautaire = entreprise.numero_tva_intracommunautaire
        etablissement.entreprise_forme_juridique = entreprise.forme_juridique
        etablissement.entreprise_forme_juridique_code = entreprise.forme_juridique_code
        etablissement.entreprise_nom_commercial = entreprise.nom_commercial
        etablissement.entreprise_raison_sociale = entreprise.raison_sociale
        etablissement.entreprise_siret_siege_social = entreprise.siret_siege_social
        etablissement.entreprise_code_effectif_entreprise = entreprise.code_effectif_entreprise
        etablissement.entreprise_date_creation = entreprise.date_creation
        etablissement.entreprise_nom = entreprise.nom
        etablissement.entreprise_prenom = entreprise.prenom

        association = entreprise.rna_information

        if association && association.association_id
          etablissement.association_rna = association.association_id
          etablissement.association_titre = association.titre
          etablissement.association_objet = association.objet
          etablissement.association_date_creation = association.date_creation
          etablissement.association_date_declaration = association.date_declaration
          etablissement.association_date_publication = association.date_publication
        end

        etablissement.save
      end
    end
  end
end
