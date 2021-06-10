# frozen_string_literal: true

describe APIParticulier::Services::SanitizeData do
  let(:foyer_fiscal_attrs) do
    { annee: 2020, adresse: "13 rue de la Plage 97615 Pamanzi" }
  end

  let(:avis_attrs) do
    {
      declarant1: { nom: "FERRI", nom_de_naissance: "FERRI", prenoms: "Karine", date_de_naissance: "12/08/1978" },
      declarant2: { nom: "", nom_de_naissance: "", prenoms: "", date_de_naissance: "12/08/1978" },
      date_de_recouvrement: "09/10/2020",
      date_d_etablissement: "07/07/2020",
      erreur_correctif: nil,
      nombre_de_parts: 1,
      nombre_de_personnes_a_charge: 0,
      revenu_brut_global: 38814,
      revenu_imposable: 38814,
      impot_revenu_net_avant_corrections: 38814,
      montant_de_l_impot: 38814,
      revenu_fiscal_de_reference: 38814,
      annee_d_imposition: "2020",
      annee_des_revenus: "2020",
      situation_familiale: nil,
      situation_partielle: "SUP DOM"
    }
  end

  let(:famille_attrs) do
    {
      adresse: {
        identite: "Madame MARIE DUPONT",
        complement_d_identite: "ESCALIER B",
        complement_d_identite_geo: nil,
        numero_et_rue: "123 RUE BIDON",
        code_postal_et_ville: "12345 CONDAT",
        lieu_dit: nil,
        pays: "FRANCE"
      },
      allocataires: [
        {
          noms_et_prenoms: "MARIE DUPONT",
          date_de_naissance: "12111971",
          sexe: "F"
        }, {
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
    }
  end

  let(:situation_attrs) do
    {
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
      telephone2: nil,
      civilite: "M.",
      adresse: {
        code_postal: "75018",
        insee_commune: "75118",
        localite: "75018 Paris",
        ligne_voie: "3 rue des Huttes",
        ligne_nom_du_detinataire: "MOUSTAKI",
        ligne_complement_d_adresse: nil,
        ligne_complement_de_distribution: nil,
        ligne_complement_destinataire: nil
      }
    }
  end

  let(:etudiant_attrs) do
    {
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
  end

  let(:foyer_fiscal) { APIParticulier::Entities::DGFIP::FoyerFiscal.new(**foyer_fiscal_attrs) }
  let(:avis) { APIParticulier::Entities::DGFIP::AvisImposition.new(**avis_attrs) }
  let(:famille) { APIParticulier::Entities::CAF::Famille.new(**famille_attrs) }
  let(:situation) { APIParticulier::Entities::PoleEmploi::SituationPoleEmploi.new(**situation_attrs) }
  let(:etudiant) { APIParticulier::Entities::MESRI::Etudiant.new(**etudiant_attrs) }

  let(:data) do
    {
      dgfip: { avis_imposition: avis, foyer_fiscal: foyer_fiscal },
      caf: {
        allocataires: famille.allocataires,
        enfants: famille.enfants,
        adresse: famille.adresse,
        quotient_familial: famille.quotient_familial,
        annee: famille.annee,
        mois: famille.mois
      },
      pole_emploi: { situation: situation },
      mesri: { statut_etudiant: etudiant }
    }
  end

  let(:service) { APIParticulier::Services::SanitizeData.new }

  subject { service.call(data, mask) }

  context "quand on picore des données un peu partout" do
    let(:mask) do
      {
        dgfip: {
          avis_imposition: {
            annee_d_imposition: 1,
            annee_des_revenus: 0,
            date_d_etablissement: 0,
            date_de_recouvrement: 0,
            declarant1: { date_de_naissance: 1, nom: 1, nom_de_naissance: 0, prenoms: 1 },
            declarant2: { date_de_naissance: 0, nom: 0, nom_de_naissance: 0, prenoms: 0 },
            erreur_correctif: 0,
            impot_revenu_net_avant_corrections: 0,
            montant_de_l_impot: 0,
            nombre_de_parts: 1,
            nombre_de_personnes_a_charge: 0,
            revenu_brut_global: 0,
            revenu_fiscal_de_reference: 0,
            revenu_imposable: 0,
            situation_familiale: 0,
            situation_partielle: 0
          },
          foyer_fiscal: { adresse: 1, annee: 0 }
        },
        caf: {
          adresse: {
            code_postal_et_ville: 1,
            complement_d_identite: 0,
            complement_d_identite_geo: 0,
            identite: 0,
            lieu_dit: 0,
            numero_et_rue: 0,
            pays: 1
          },
          allocataires: { date_de_naissance: 0, noms_et_prenoms: 1, sexe: 1 },
          annee: 1,
          enfants: { date_de_naissance: 1, noms_et_prenoms: 0, sexe: 1 },
          mois: 0,
          quotient_familial: 1
        },
        pole_emploi: {
          situation: {
            adresse: {
              code_postal: 0,
              insee_commune: 1,
              ligne_complement_d_adresse: 0,
              ligne_complement_de_distribution: 0,
              ligne_complement_destinataire: 0,
              ligne_nom_du_detinataire: 0,
              ligne_voie: 0,
              localite: 0
            },
            categorie_d_inscription: 0,
            civilite: 0,
            code_de_certification_cnav: 0,
            date_d_inscription: 0,
            date_de_la_prochaine_convocation: 0,
            date_de_naissance: 0,
            date_de_radiation: 0,
            email: 1,
            identifiant: 1,
            nom: 0,
            nom_d_usage: 0,
            prenom: 0,
            sexe: 0,
            telephone: 0,
            telephone2: 0
          }
        },
        mesri: {
          statut_etudiant: {
            date_de_naissance: 0,
            ine: 1,
            inscriptions: {
              code_commune: 0,
              date_de_debut_d_inscription: 0,
              date_de_fin_d_inscription: 0,
              etablissement: { nom: 1, uai: 0 },
              regime: 0,
              statut: 1
            },
            nom: 0,
            prenom: 0
          }
        }
      }
    end

    let(:foyer_fiscal_assaini) do
      { adresse: "13 rue de la Plage 97615 Pamanzi" }
    end

    let(:avis_assaini) do
      {
        declarant1: { nom: "FERRI", prenoms: "Karine", date_de_naissance: "12/08/1978" },
        nombre_de_parts: 1,
        annee_d_imposition: "2020"
      }
    end

    let(:famille_assainie) do
      {
        adresse: {
          code_postal_et_ville: "12345 CONDAT",
          pays: "FRANCE"
        },
        allocataires: [
          { noms_et_prenoms: "MARIE DUPONT", sexe: "F" },
          { noms_et_prenoms: "JEAN DUPONT", sexe: "M" }
        ],
        enfants: [
          { date_de_naissance: "11122016", sexe: "F" }
        ],
        quotient_familial: 1754,
        annee: 2020
      }
    end

    let(:situation_assainie) do
      {
        email: "georges@moustaki.fr",
        identifiant: "georges_moustaki_77",
        adresse: {
          insee_commune: "75118"
        }
      }
    end

    let(:etudiant_assaini) do
      {
        ine: "0906018155T",
        inscriptions: [
          {
            statut: "admis",
            etablissement: {
              nom: "EGC AIN BOURG EN BRESSE EC GESTION ET COMMERCE (01000)"
            }
          }
        ]
      }
    end

    let(:sanitized_data) do
      {
        dgfip: { avis_imposition: avis_assaini, foyer_fiscal: foyer_fiscal_assaini },
        caf: famille_assainie,
        pole_emploi: { situation: situation_assainie },
        mesri: { statut_etudiant: etudiant_assaini }
      }
    end

    it "doit retourner les seules informations retenues" do
      expect(subject).to eq(sanitized_data)
    end
  end

  context "quand on ne veut récupérer que le quotient familial" do
    let(:mask) do
      {
        caf: { quotient_familial: 1 }
      }
    end

    let(:sanitized_data) do
      {
        dgfip: {},
        caf: { quotient_familial: 1754 },
        pole_emploi: {},
        mesri: {}
      }
    end

    it "ne doit retourner aucune informations" do
      expect(subject).to eq(sanitized_data)
    end
  end

  context "quand on ne veut récupérer aucune donnée" do
    let(:mask) do
      {
        dgfip: {},
        caf: {},
        pole_emploi: {},
        mesri: {}
      }
    end

    let(:sanitized_data) do
      {
        dgfip: {},
        caf: {},
        pole_emploi: {},
        mesri: {}
      }
    end

    it "ne doit retourner aucune informations" do
      expect(subject).to eq(sanitized_data)
    end
  end

  context "quand on veut récupérer toutes les données" do
    let(:mask) do
      {
        dgfip: {
          avis_imposition: {
            annee_d_imposition: 1,
            annee_des_revenus: 1,
            date_d_etablissement: 1,
            date_de_recouvrement: 1,
            declarant1: { date_de_naissance: 1, nom: 1, nom_de_naissance: 1, prenoms: 1 },
            declarant2: { date_de_naissance: 1, nom: 1, nom_de_naissance: 1, prenoms: 1 },
            erreur_correctif: 1,
            impot_revenu_net_avant_corrections: 1,
            montant_de_l_impot: 1,
            nombre_de_parts: 1,
            nombre_de_personnes_a_charge: 1,
            revenu_brut_global: 1,
            revenu_fiscal_de_reference: 1,
            revenu_imposable: 1,
            situation_familiale: 1,
            situation_partielle: 1
          },
          foyer_fiscal: { adresse: 1, annee: 1 }
        },
        caf: {
          adresse: {
            code_postal_et_ville: 1,
            complement_d_identite: 1,
            complement_d_identite_geo: 1,
            identite: 1,
            lieu_dit: 1,
            numero_et_rue: 1,
            pays: 1
          },
          allocataires: { date_de_naissance: 1, noms_et_prenoms: 1, sexe: 1 },
          annee: 1,
          enfants: { date_de_naissance: 1, noms_et_prenoms: 1, sexe: 1 },
          mois: 1,
          quotient_familial: 1
        },
        pole_emploi: {
          situation: {
            adresse: {
              code_postal: 1,
              insee_commune: 1,
              ligne_complement_d_adresse: 1,
              ligne_complement_de_distribution: 1,
              ligne_complement_destinataire: 1,
              ligne_nom_du_detinataire: 1,
              ligne_voie: 1,
              localite: 1
            },
            categorie_d_inscription: 1,
            civilite: 1,
            code_de_certification_cnav: 1,
            date_d_inscription: 1,
            date_de_la_prochaine_convocation: 1,
            date_de_naissance: 1,
            date_de_radiation: 1,
            email: 1,
            identifiant: 1,
            nom: 1,
            nom_d_usage: 1,
            prenom: 1,
            sexe: 1,
            telephone: 1,
            telephone2: 1
          }
        },
        mesri: {
          statut_etudiant: {
            date_de_naissance: 1,
            ine: 1,
            inscriptions: {
              code_commune: 1,
              date_de_debut_d_inscription: 1,
              date_de_fin_d_inscription: 1,
              etablissement: { nom: 1, uai: 1 },
              regime: 1,
              statut: 1
            },
            nom: 1,
            prenom: 1
          }
        }
      }
    end

    let(:sanitized_data) do
      {
        dgfip: { avis_imposition: avis_attrs, foyer_fiscal: foyer_fiscal_attrs },
        caf: famille_attrs,
        pole_emploi: { situation: situation_attrs },
        mesri: { statut_etudiant: etudiant_attrs }
      }
    end

    it "doit retourner toutes informations" do
      expect(subject).to eq(sanitized_data)
    end
  end
end
