describe NewAdministrateur::SourcesParticulierController, type: :controller do
  let(:admin) { create(:administrateur) }

  before { sign_in(admin.user) }

  describe "#show" do
    let(:procedure) { create(:procedure, administrateur: admin, api_particulier_scopes: ['cnaf_enfants'], api_particulier_sources: { cnaf: { enfants: ['noms_prenoms'] } }) }

    render_views

    subject { get :show, params: { procedure_id: procedure.id } }

    it 'renders the sources form' do
      expect(subject.body).to include(I18n.t('api_particulier.providers.cnaf.scopes.enfants.date_de_naissance'))
      expect(subject.body).to have_selector("input#api_particulier_sources_cnaf_enfants_[value=noms_prenoms][checked=checked]")

      expect(subject.body).to have_selector("input#api_particulier_sources_cnaf_enfants_[value=date_de_naissance]")
      expect(subject.body).not_to have_selector("input#api_particulier_sources_cnaf_enfants_[value=date_de_naissance][checked=checked]")
    end
  end
end
