# frozen_string_literal: true

describe Administrateurs::SourcesParticulierController, type: :controller do
  let(:admin) { administrateurs(:default_admin) }

  before { sign_in(admin.user) }

  describe "#show" do
    let(:procedure) { create(:procedure, administrateur: admin, api_particulier_scopes: ['cnaf_enfants'], api_particulier_sources: { cnaf: { enfants: ['nomPrenom'] } }) }

    render_views

    subject { get :show, params: { procedure_id: procedure.id } }

    it 'renders the sources form' do
      expect(subject.body).to include(I18n.t('api_particulier.providers.cnaf.scopes.enfants.dateDeNaissance'))
      expect(subject.body).to have_selector("input#api_particulier_sources_cnaf_enfants_[value=nomPrenom][checked=checked]")

      expect(subject.body).to have_selector("input#api_particulier_sources_cnaf_enfants_[value=dateDeNaissance]")
      expect(subject.body).not_to have_selector("input#api_particulier_sources_cnaf_enfants_[value=dateDeNaissance][checked=checked]")
    end
  end

  describe "#update" do
    let(:procedure) { create(:procedure, administrateur: admin, api_particulier_scopes: ['cnaf_enfants'], api_particulier_sources: {}) }
    let(:params) { { procedure_id: procedure.id }.merge(requested_sources) }

    before do
      patch :update, params: params
      procedure.reload
    end

    context 'when no source is requested' do
      let(:requested_sources) { {} }

      it { expect(procedure.api_particulier_sources).to be_empty }
    end

    context 'when a forbidden source is requested' do
      let(:requested_sources) do
        {
          api_particulier_sources: { cnaf: { enfants: ['forbidden'] } },
        }
      end

      it { expect(procedure.api_particulier_sources).to be_empty }
    end

    context 'when an authorized source is requested' do
      let(:requested_sources) do
        {
          api_particulier_sources: { cnaf: { enfants: ['nomPrenom'] } },
        }
      end

      it 'saves the source' do
        expect(procedure.api_particulier_sources).to eq("cnaf" => { "enfants" => ["nomPrenom"] })
        expect(flash.notice).to eq(I18n.t(".administrateurs.sources_particulier.update.sources_ok"))
      end
    end
  end
end
