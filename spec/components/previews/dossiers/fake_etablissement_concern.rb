# frozen_string_literal: true

module Dossiers::FakeEtablissementConcern
  extend ActiveSupport::Concern

  included do
    private

    def etablissement
      et = Etablissement.new(
        siret: "11004601800013",
        siege_social: true,
        naf: "84.11Z",
        libelle_naf: "Administration publique générale",
        adresse: "MINISTERE DE LA CULTURE\r\n\r\n\r\n182 RUE SAINT-HONORE\r\n\r\n75001 PARIS\r\nFRANCE",
        numero_voie: "182",
        type_voie: "RUE",
        nom_voie: "SAINT-HONORE",
        code_postal: "75001",
        localite: "PARIS",
        code_insee_localite: "75101",
        entreprise_siren: "110046018",
        entreprise_capital_social: 537_100_000,
        entreprise_numero_tva_intracommunautaire: "FR21110046018",
        entreprise_forme_juridique: "Ministère",
        entreprise_forme_juridique_code: "7113",
        entreprise_nom_commercial: 'GREJKL',
        entreprise_raison_sociale: "MINISTERE DE LA CULTURE",
        entreprise_siret_siege_social: "11004601800013",
        entreprise_code_effectif_entreprise: "22",
        entreprise_date_creation: Date.new(1946, 10, 17),
        entreprise_nom: 'c est un nom',
        entreprise_prenom: 'c est un prenom',
        association_rna: "W072000535",
        association_titre: "ASSOCIATION POUR LA PROMOTION DE SPECTACLES AU CHATEAU DE ROCHEMAURE",
        association_objet: "mise en oeuvre et réalisation de spectacles au chateau de rochemaure",
        association_date_creation: "1990-04-24",
        association_date_declaration: "2014-11-28",
        association_date_publication: "1990-05-16",
        diffusable_commercialement: true,
        entreprise_effectif_mois: 03,
        entreprise_effectif_annee: 2020,
        entreprise_effectif_mensuel: 100.5,
        entreprise_effectif_annuel: 123,
        entreprise_effectif_annuel_annee: 2020,
        entreprise_bilans_bdf:,
        entreprise_bilans_bdf_monnaie:,
        enseigne: nil,
        entreprise_etat_administratif: "actif",
        exercices: [
          Exercice.new(
                      ca: '12345678',
                      date_fin_exercice: "2014-12-30 23:00:00",
                      date_fin_exercice_timestamp: 1419980400
                    ),
          Exercice.new(
                      ca: '87654321',
                      date_fin_exercice: "2013-12-30 23:00:00",
                      date_fin_exercice_timestamp: 1419980400
                    )
        ]
      )

      et.define_singleton_method(:entreprise_attestation_sociale) do
        { action: 'index', controller: 'users' }.tap { def it.attached? = true }
      end

      et.define_singleton_method(:entreprise_attestation_fiscale) do
        { action: 'index', controller: 'users' }.tap { def it.attached? = true }
      end

      et
    end

    def entreprise_bilans_bdf
      entreprise_bilans['bilans']
    end

    def entreprise_bilans_bdf_monnaie
      entreprise_bilans['monnaie']
    end

    def entreprise_bilans
      JSON.parse(File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf_v2.json'))
    end
  end
end
