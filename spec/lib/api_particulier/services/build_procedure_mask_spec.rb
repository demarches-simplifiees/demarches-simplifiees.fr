# frozen_string_literal: true

describe APIParticulier::Services::BuildProcedureMask do
  let(:procedure) { Procedure.new(api_particulier_scopes: scopes, api_particulier_sources: sources) }
  let(:service) { APIParticulier::Services::BuildProcedureMask.new(procedure) }

  subject { service.call }

  context "without scope" do
    let(:scopes) { [] }
    let(:sources) { nil }

    let(:built_mask) do
      {
        dgfip: {},
        caf: {},
        pole_emploi: {},
        mesri: {}
      }
    end

    it { expect(subject).to eql(built_mask) }
  end

  context "with 'dgfip_adresse' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:dgfip_adresse]] }

    let(:built_mask) do
      {
        dgfip: { foyer_fiscal: { adresse: nil, annee: nil } },
        caf: {},
        pole_emploi: {},
        mesri: {}
      }
    end

    context "but without selected sources" do
      let(:sources) { nil }

      it { expect(subject).to eql(built_mask) }
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          dgfip: { foyer_fiscal: { annee: 0, adresse: 1 } }
        }
      end

      it { expect(subject).to eql(built_mask) }
    end
  end

  context "with 'dgfip_avis_imposition' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:dgfip_avis_imposition]] }

    let(:built_mask) do
      {
        dgfip: {
          avis_imposition: {
            annee_d_imposition: nil,
            annee_des_revenus: nil,
            date_d_etablissement: nil,
            date_de_recouvrement: nil,
            declarant1: { date_de_naissance: nil, nom: nil, nom_de_naissance: nil, prenoms: nil },
            declarant2: { date_de_naissance: nil, nom: nil, nom_de_naissance: nil, prenoms: nil },
            erreur_correctif: nil,
            impot_revenu_net_avant_corrections: nil,
            montant_de_l_impot: nil,
            nombre_de_parts: nil,
            nombre_de_personnes_a_charge: nil,
            revenu_brut_global: nil,
            revenu_fiscal_de_reference: nil,
            revenu_imposable: nil,
            situation_familiale: nil,
            situation_partielle: nil
          }
        },
        caf: {},
        pole_emploi: {},
        mesri: {}
      }
    end

    context "but without selected sources" do
      let(:sources) { nil }

      it { expect(subject).to eql(built_mask) }
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          dgfip: {
            avis_imposition: {
              declarant1: { nom: 1, prenoms: 0, nom_de_naissance: 0, date_de_naissance: 1 }
            }
          }
        }
      end

      it { expect(subject).to eql(built_mask) }
    end
  end

  context "with all DGFIP scopes" do
    let(:scopes) { [APIParticulier::Types::Scope[:dgfip_avis_imposition], APIParticulier::Types::Scope[:dgfip_adresse]] }

    let(:built_mask) do
      {
        dgfip: {
          avis_imposition: {
            annee_d_imposition: nil,
            annee_des_revenus: nil,
            date_d_etablissement: nil,
            date_de_recouvrement: nil,
            declarant1: { date_de_naissance: nil, nom: nil, nom_de_naissance: nil, prenoms: nil },
            declarant2: { date_de_naissance: nil, nom: nil, nom_de_naissance: nil, prenoms: nil },
            erreur_correctif: nil,
            impot_revenu_net_avant_corrections: nil,
            montant_de_l_impot: nil,
            nombre_de_parts: nil,
            nombre_de_personnes_a_charge: nil,
            revenu_brut_global: nil,
            revenu_fiscal_de_reference: nil,
            revenu_imposable: nil,
            situation_familiale: nil,
            situation_partielle: nil
          },
          foyer_fiscal: { adresse: nil, annee: nil }
        },
        caf: {},
        pole_emploi: {},
        mesri: {}
      }
    end

    context "but without selected sources" do
      let(:sources) { nil }

      it { expect(subject).to eql(built_mask) }
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          dgfip: {
            foyer_fiscal: { annee: 0, adresse: 1 },
            avis_imposition: {
              declarant1: { nom: 1, prenoms: 0, nom_de_naissance: 0, date_de_naissance: 1 }
            }
          }
        }
      end

      it { expect(subject).to eql(built_mask) }
    end
  end

  context "with all CAF scopes" do
    let(:scopes) do
      [
        APIParticulier::Types::Scope[:cnaf_allocataires],
        APIParticulier::Types::Scope[:cnaf_enfants],
        APIParticulier::Types::Scope[:cnaf_adresse],
        APIParticulier::Types::Scope[:cnaf_quotient_familial]
      ]
    end

    let(:built_mask) do
      {
        dgfip: {},
        caf: {
          adresse: {
            code_postal_et_ville: nil,
            complement_d_identite: nil,
            complement_d_identite_geo: nil,
            identite: nil,
            lieu_dit: nil,
            numero_et_rue: nil,
            pays: nil
          },
          allocataires: { date_de_naissance: nil, noms_et_prenoms: nil, sexe: nil },
          annee: nil,
          enfants: { date_de_naissance: nil, noms_et_prenoms: nil, sexe: nil },
          mois: nil,
          quotient_familial: nil
        },
        pole_emploi: {},
        mesri: {}
      }
    end

    context "but without selected sources" do
      let(:sources) { nil }

      it { expect(subject).to eql(built_mask) }
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          caf: {
            allocataires: { sexe: 0, noms_et_prenoms: 1, date_de_naissance: 0 },
            quotient_familial: 1
          }
        }
      end

      it { expect(subject).to eql(built_mask) }
    end
  end

  context "with 'pole_emploi_situation' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:pe_situation_individu]] }

    let(:built_mask) do
      {
        dgfip: {},
        caf: {},
        pole_emploi: {
          situation: {
            adresse: {
              code_postal: nil,
              insee_commune: nil,
              ligne_complement_d_adresse: nil,
              ligne_complement_de_distribution: nil,
              ligne_complement_destinataire: nil,
              ligne_nom_du_detinataire: nil,
              ligne_voie: nil,
              localite: nil
            },
            categorie_d_inscription: nil,
            civilite: nil,
            code_de_certification_cnav: nil,
            date_d_inscription: nil,
            date_de_la_prochaine_convocation: nil,
            date_de_naissance: nil,
            date_de_radiation: nil,
            email: nil,
            identifiant: nil,
            nom: nil,
            nom_d_usage: nil,
            prenom: nil,
            sexe: nil,
            telephone: nil,
            telephone2: nil
          }
        },
        mesri: {}
      }
    end

    context "but without selected sources" do
      let(:sources) { nil }

      it { expect(subject).to eql(built_mask) }
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          pole_emploi: { situation: { email: 1, nom: 0 } }
        }
      end

      it { expect(subject).to eql(built_mask) }
    end
  end

  context "with 'mesri_statut_etudiant' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:mesri_statut_etudiant]] }

    let(:built_mask) do
      {
        dgfip: {},
        caf: {},
        pole_emploi: {},
        mesri: {
          statut_etudiant: {
            date_de_naissance: nil,
            ine: nil,
            inscriptions: {
              code_commune: nil,
              date_de_debut_d_inscription: nil,
              date_de_fin_d_inscription: nil,
              etablissement: { nom: nil, uai: nil },
              regime: nil,
              statut: nil
            },
            nom: nil,
            prenom: nil
          }
        }
      }
    end

    context "but without selected sources" do
      let(:sources) { nil }

      it { expect(subject).to eql(built_mask) }
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          mesri: {
            statut_etudiant: { inscriptions: { etablissement: { nom: 1, uai: 0 } } }
          }
        }
      end

      it { expect(subject).to eql(built_mask) }
    end
  end
end
