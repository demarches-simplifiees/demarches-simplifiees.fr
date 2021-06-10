# frozen_string_literal: true

describe APIParticulier::Services::BuildData do
  let(:service) { APIParticulier::Services::BuildData.new }

  subject { service.call(raw: raw) }

  context "without data" do
    let(:raw) do
      {
        dgfip: {},
        caf: {},
        pole_emploi: {},
        mesri: {}
      }
    end

    let(:data) do
      {
        dgfip: nil,
        caf: nil,
        pole_emploi: nil,
        mesri: nil
      }
    end

    it { expect(subject).to eql(data) }
  end

  context "with DGFIP foyer fiscal data" do
    let(:raw) do
      {
        caf: {},
        dgfip: { foyer_fiscal: { annee: 2020, adresse: "13 rue de la Plage 97615 Pamanzi" } },
        mesri: {},
        pole_emploi: {}
      }
    end

    let(:foyer_fiscal) do
      APIParticulier::Entities::DGFIP::FoyerFiscal.new(
        annee: 2020,
        adresse: "13 rue de la Plage 97615 Pamanzi"
      )
    end

    let(:avis) do
      APIParticulier::Entities::DGFIP::AvisImposition.new(foyer_fiscal: {
        annee: 2020,
        adresse: "13 rue de la Plage 97615 Pamanzi"
      })
    end

    let(:data) do
      {
        dgfip: avis,
        caf: nil,
        pole_emploi: nil,
        mesri: nil
      }
    end

    it { expect(subject).to eq(data) }
    it { expect(subject[:dgfip].foyer_fiscal).to eq(foyer_fiscal) }
  end

  context "with some DGFIP data" do
    let(:raw) do
      {
        dgfip: {
          avis_imposition: {
            declarant1: {
              nom: "FERRI",
              prenoms: "Karine",
              date_de_naissance: "12/08/1978"
            },
            revenu_fiscal_de_reference: 38814
          },
          foyer_fiscal: {
            annee: 2020,
            adresse: "13 rue de la Plage 97615 Pamanzi"
          }
        },
        caf: {
          adresse: {
            identite: "Madame MARIE DUPONT",
            complement_d_identite_geo: "ESCALIER B",
            numero_et_rue: "123 RUE BIDON",
            code_postal_et_ville: "12345 CONDAT",
            pays: "FRANCE"
          },
          allocataires: [
            {
              noms_et_prenoms: "MARIE DUPONT",
              date_de_naissance: "12111971",
              sexe: "F"
            },
            {
              noms_et_prenoms: "JEAN DUPONT",
              date_de_naissance: "18101969",
              sexe: "M"
            }
          ],
          enfants: [
            {
              noms_et_prenoms: "LUCIE DUPONT",
              date_de_naissance: "11122016",
              sexe: "F"
            }
          ],
          quotient_familial: 1754,
          annee: 2020,
          mois: 12
        },
        pole_emploi: {
          situation: {
            email: "georges@moustaki.fr",
            nom: "Moustaki",
            nom_d_usage: "Moustaki",
            prenom: "Georges",
            identifiant: "georges_moustaki_77",
            sexe: "M",
            date_de_naissance: "1934-05-03T00:00:00",
            date_d_inscription: "1965-05-03T00:00:00",
            date_de_radiation: "1966-05-03T00:00:00",
            date_de_la_prochaine_convocation: "1966-05-03T00:00:00",
            categorie_d_inscription: "3",
            code_de_certification_cnav: "VC",
            telephone: "0629212921",
            civilite: "M.",
            adresse: {
              code_postal: "75018",
              insee_commune: "75118",
              localite: "75018 Paris",
              ligne_voie: "3 rue des Huttes",
              ligne_nom_du_detinataire: "MOUSTAKI"
            }
          }
        },
        mesri: {
          statut_etudiant: {
            ine: "0906018155T",
            nom: "Dupont",
            prenom: "Gaëtan",
            date_de_naissance: "1999-10-12T00:00:00",
            inscriptions: [
              {
                date_de_debut_d_inscription: "2019-09-01T00:00:00",
                date_de_fin_d_inscription: "2020-08-31T00:00:00",
                statut: "admis",
                regime: "formation initiale",
                code_commune: "44000",
                etablissement: {
                  uai: "0011402U",
                  nom: "EGC AIN BOURG EN BRESSE EC GESTION ET COMMERCE (01000)"
                }
              }
            ]
          }
        }
      }
    end

    let(:foyer_fiscal) do
      APIParticulier::Entities::DGFIP::FoyerFiscal.new(
        annee: 2020,
        adresse: "13 rue de la Plage 97615 Pamanzi"
      )
    end

    let(:avis) do
      APIParticulier::Entities::DGFIP::AvisImposition.new(
        declarant1: {
          nom: "FERRI",
          prenoms: "Karine",
          date_de_naissance: "12/08/1978"
        },
        foyer_fiscal: {
          annee: 2020,
          adresse: "13 rue de la Plage 97615 Pamanzi"
        },
        revenu_fiscal_de_reference: 38814
      )
    end

    let(:famille) do
      APIParticulier::Entities::CAF::Famille.new(
        adresse: {
          identite: "Madame MARIE DUPONT",
          complement_d_identite_geo: "ESCALIER B",
          numero_et_rue: "123 RUE BIDON",
          code_postal_et_ville: "12345 CONDAT",
          pays: "FRANCE"
        },
        allocataires: [
          {
            noms_et_prenoms: "MARIE DUPONT",
            date_de_naissance: "12111971",
            sexe: "F"
          },
          {
            noms_et_prenoms: "JEAN DUPONT",
            date_de_naissance: "18101969",
            sexe: "M"
          }
        ],
        enfants: [
          {
            noms_et_prenoms: "LUCIE DUPONT",
            date_de_naissance: "11122016",
            sexe: "F"
          }
        ],
        quotient_familial: 1754,
        annee: 2020,
        mois: 12
      )
    end

    let(:situation) do
      APIParticulier::Entities::PoleEmploi::SituationPoleEmploi.new(
        email: "georges@moustaki.fr",
        nom: "Moustaki",
        nom_d_usage: "Moustaki",
        prenom: "Georges",
        identifiant: "georges_moustaki_77",
        sexe: "M",
        date_de_naissance: "1934-05-03T00:00:00",
        date_d_inscription: "1965-05-03T00:00:00",
        date_de_radiation: "1966-05-03T00:00:00",
        date_de_la_prochaine_convocation: "1966-05-03T00:00:00",
        categorie_d_inscription: "3",
        code_de_certification_cnav: "VC",
        telephone: "0629212921",
        civilite: "M.",
        adresse: {
          code_postal: "75018",
          insee_commune: "75118",
          localite: "75018 Paris",
          ligne_voie: "3 rue des Huttes",
          ligne_nom_du_detinataire: "MOUSTAKI"
        }
      )
    end

    let(:etudiant) do
      APIParticulier::Entities::MESRI::Etudiant.new(
        ine: "0906018155T",
        nom: "Dupont",
        prenom: "Gaëtan",
        date_de_naissance: "1999-10-12T00:00:00",
        inscriptions: [
          {
            date_de_debut_d_inscription: "2019-09-01T00:00:00",
            date_de_fin_d_inscription: "2020-08-31T00:00:00",
            statut: "admis",
            regime: "formation initiale",
            code_commune: "44000",
            etablissement: {
              uai: "0011402U",
              nom: "EGC AIN BOURG EN BRESSE EC GESTION ET COMMERCE (01000)"
            }
          }
        ]
      )
    end

    let(:data) do
      {
        dgfip: avis,
        caf: famille,
        pole_emploi: situation,
        mesri: etudiant
      }
    end

    it { expect(subject).to eq(data) }
    it { expect(subject[:dgfip].foyer_fiscal).to eq(foyer_fiscal) }
  end
end
