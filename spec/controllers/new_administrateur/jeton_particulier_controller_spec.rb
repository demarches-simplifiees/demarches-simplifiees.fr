describe NewAdministrateur::JetonParticulierController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateur: admin) }

  before do
    sign_in(admin.user)
  end

  describe "GET #api_particulier" do
    let(:procedure) { create :procedure, :with_service, administrateur: admin }

    render_views

    subject { get :api_particulier, params: { procedure_id: procedure.id } }

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.body).to have_content('Jeton API particulier') }
  end
end
