# frozen_string_literal: true

describe Administrateurs::JetonParticulierController, type: :controller do
  let(:admin) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure, administrateur: admin) }

  before do
    stub_const("API_PARTICULIER_URL", "https://particulier.api.gouv.fr/api")

    sign_in(admin.user)
  end

  describe "GET #api_particulier" do
    render_views

    subject { get :api_particulier, params: { procedure_id: procedure.id } }

    it do
      is_expected.to have_http_status(:success)
      expect(subject.body).to have_content('Jeton API particulier')
    end
  end

  describe "GET #show" do
    subject { get :show, params: { procedure_id: procedure.id } }

    it { is_expected.to have_http_status(:success) }
  end

  describe "PATCH #update" do
    let(:params) { { procedure_id: procedure.id, procedure: { api_particulier_token: token } } }

    subject { patch :update, params: params }

    context "when jeton has a valid shape" do
      let(:token) { "d7e9c9f4c3ca00caadde31f50fd4521a" }
      before do
        VCR.use_cassette(cassette) do
          subject
        end
      end

      context "and the api response is a success" do
        let(:cassette) { "api_particulier/success/introspect" }
        let(:procedure) { create(:procedure, administrateur: admin, api_particulier_sources: { cnaf: { allocataires: ['nomPrenom'] } }) }

        it 'saves the jeton' do
          expect(flash.alert).to be_nil
          expect(flash.notice).to eq("Le jeton a bien été mis à jour")
          procedure.reload
          expect(procedure.api_particulier_token).to eql(token)
          expect(procedure.api_particulier_scopes).to contain_exactly(
            'cnaf_adresse',
            'cnaf_allocataires',
            'cnaf_enfants',
            'cnaf_quotient_familial',
            'dgfip_adresse_fiscale_annee',
            'dgfip_adresse_fiscale_taxation',
            'dgfip_annee_impot',
            'dgfip_annee_revenus',
            'dgfip_date_etablissement',
            'dgfip_date_recouvrement',
            'dgfip_declarant1_date_naissance',
            'dgfip_declarant1_nom',
            'dgfip_declarant1_nom_naissance',
            'dgfip_declarant1_prenoms',
            'dgfip_declarant2_date_naissance',
            'dgfip_declarant2_nom',
            'dgfip_declarant2_nom_naissance',
            'dgfip_declarant2_prenoms',
            'dgfip_erreur_correctif',
            'dgfip_impot_revenu_net_avant_corrections',
            'dgfip_montant_impot',
            'dgfip_nombre_parts',
            'dgfip_nombre_personnes_a_charge',
            'dgfip_revenu_brut_global',
            'dgfip_revenu_fiscal_reference',
            'dgfip_revenu_imposable',
            'dgfip_situation_familiale',
            'dgfip_situation_partielle',
            'pole_emploi_identite',
            'pole_emploi_adresse',
            'pole_emploi_contact',
            'pole_emploi_inscription',
            'mesri_identifiant',
            'mesri_identite',
            'mesri_inscription_etudiant',
            'mesri_inscription_autre',
            'mesri_admission',
            'mesri_etablissements'
          )
          expect(procedure.api_particulier_sources).to be_empty
        end
      end

      context "and the api response is a success but with an empty scopes" do
        let(:cassette) { "api_particulier/success/introspect_empty_scopes" }

        it 'rejects the jeton' do
          expect(flash.alert).to include("le jeton n’a pas acces aux données")
          expect(flash.notice).to be_nil
          expect(procedure.reload.api_particulier_token).not_to eql(token)
        end
      end

      context "and the api response is not unauthorized" do
        let(:cassette) { "api_particulier/unauthorized/introspect" }

        it 'rejects the jeton' do
          expect(flash.alert).to include("Mise à jour impossible : le jeton n’a pas été trouvé ou n’est pas actif")
          expect(flash.notice).to be_nil
          expect(procedure.reload.api_particulier_token).not_to eql(token)
        end
      end
    end

    context "when jeton is invalid and no network call is made" do
      let(:token) { "jet0n 1nvalide" }

      before { subject }

      it 'rejects the jeton' do
        expect(flash.alert.first).to include("pas le bon format")
        expect(flash.notice).to be_nil
        expect(procedure.reload.api_particulier_token).not_to eql(token)
      end
    end
  end
end
