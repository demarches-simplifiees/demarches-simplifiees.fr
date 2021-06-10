# frozen_string_literal: true

describe APIParticulier::Services::CheckScopeSources do
  let(:scopes) { nil }

  let(:sources) do
    {
      caf: {
        mois: 0,
        annee: 0,
        adresse: {
          pays: 0,
          identite: 0,
          lieu_dit: 0,
          numero_et_rue: 0,
          code_postal_et_ville: 0,
          complement_d_identite: 0,
          complement_d_identite_geo: 0
        },
        enfants: { sexe: 0, noms_et_prenoms: 0, date_de_naissance: 0 },
        allocataires: { sexe: 0, noms_et_prenoms: 1, date_de_naissance: 0 },
        quotient_familial: 1
      },
      dgfip: {
        foyer_fiscal: { annee: 1, adresse: 0 },
        avis_imposition: {
          declarant1: { nom: 1, prenoms: 0, nom_de_naissance: 0, date_de_naissance: 1 },
          declarant2: { nom: 1, prenoms: 0, nom_de_naissance: 0, date_de_naissance: 1 },
          nombre_de_parts: 0,
          erreur_correctif: 0,
          revenu_imposable: 0,
          annee_des_revenus: 0,
          annee_d_imposition: 0,
          montant_de_l_impot: 0,
          revenu_brut_global: 0,
          situation_familiale: 1,
          situation_partielle: 0,
          date_d_etablissement: 0,
          date_de_recouvrement: 0,
          revenu_fiscal_de_reference: 0,
          nombre_de_personnes_a_charge: 0,
          impot_revenu_net_avant_corrections: 0
        }
      },
      mesri: {
        statut_etudiant: {
          ine: 0,
          nom: 0,
          prenom: 0,
          inscriptions: {
            regime: 0,
            statut: 0,
            code_commune: 0,
            etablissement: { nom: 1, uai: 0 },
            date_de_fin_d_inscription: 0,
            date_de_debut_d_inscription: 0
          },
          date_de_naissance: 0
        }
      }
    }
  end

  let(:service) { APIParticulier::Services::CheckScopeSources.new(scopes, sources) }

  context "without scopes" do
    let(:scopes) { [] }
    let(:sources) { nil }

    it { expect(service.call(nil)).to be false }
    it { expect(service.call("dgfip_avis_imposition")).to be false }
    it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
    it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
  end

  context "with 'dgfip_adresse' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:dgfip_adresse]] }

    context "but no sources" do
      let(:sources) { nil }

      it { expect(service.call(nil)).to be false }
      it { expect(service.call("dgfip_avis_imposition")).to be false }
      it { expect(service.call("dgfip_adresse")).to be false }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
    end

    context "and some sources" do
      it { expect(service.call(nil)).to be false }
      it { expect(service.call("dgfip_avis_imposition")).to be false }
      it { expect(service.call("dgfip_adresse")).to be true }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be true }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be true }
    end
  end

  context "with 'dgfip_avis_imposition' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:dgfip_avis_imposition]] }

    context "but no sources" do
      let(:sources) { nil }

      it { expect(service.call(nil)).to be false }
      it { expect(service.call("dgfip_avis_imposition")).to be false }
      it { expect(service.call("dgfip_adresse")).to be false }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
    end

    context "and some sources" do
      it { expect(service.call(nil)).to be false }
      it { expect(service.call("dgfip_avis_imposition")).to be true }
      it { expect(service.call("dgfip_adresse")).to be false }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be true }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be true }
    end
  end

  context "with all DGFIP scopes" do
    let(:scopes) do
      [
        APIParticulier::Types::Scope[:dgfip_avis_imposition],
        APIParticulier::Types::Scope[:dgfip_adresse]
      ]
    end

    context "but no sources" do
      let(:sources) { nil }

      it { expect(service.call(nil)).to be false }
      it { expect(service.call("dgfip_avis_imposition")).to be false }
      it { expect(service.call("dgfip_adresse")).to be false }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
    end

    context "and some sources" do
      it { expect(service.call(nil)).to be false }
      it { expect(service.call("dgfip_avis_imposition")).to be true }
      it { expect(service.call("dgfip_adresse")).to be true }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be true }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be true }
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

    context "but no sources" do
      let(:sources) { nil }

      it { expect(service.call(nil)).to be false }
      it { expect(service.call("cnaf_allocataires")).to be false }
      it { expect(service.call("cnaf_enfants")).to be false }
      it { expect(service.call("cnaf_adresse")).to be false }
      it { expect(service.call("cnaf_quotient_familial")).to be false }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
    end

    context "and some sources" do
      it { expect(service.call(nil)).to be false }
      it { expect(service.call("cnaf_allocataires")).to be true }
      it { expect(service.call("cnaf_enfants")).to be false }
      it { expect(service.call("cnaf_adresse")).to be false }
      it { expect(service.call("cnaf_quotient_familial")).to be true }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be true }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be true }
    end
  end

  context "with 'pe_situation_individu' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:pe_situation_individu]] }

    context "but no sources" do
      let(:sources) { nil }

      it { expect(service.call(nil)).to be false }
      it { expect(service.call("pe_situation_individu")).to be false }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::POLE_EMPLOI_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
    end
  end

  context "with 'mesri_statut_etudiant' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:mesri_statut_etudiant]] }

    context "but no sources" do
      let(:sources) { nil }

      it { expect(service.call(nil)).to be false }
      it { expect(service.call("mesri_statut_etudiant")).to be false }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::ETUDIANT_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
    end

    context "and some sources" do
      it { expect(service.call(nil)).to be false }
      it { expect(service.call("mesri_statut_etudiant")).to be true }
      it { expect(service.call(APIParticulier::Types::DGFIP_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::ETUDIANT_SCOPES)).to be true }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be true }
    end
  end
end
