describe NewAdministrateur::MailTemplatesController, type: :controller do
  render_views
  let(:procedure) { create :procedure }
  let(:initiated_mail) { Mails::InitiatedMail.default_for_procedure(procedure) }

  let(:admin) { create(:administrateur) }

  before do
    sign_in(procedure.administrateurs.first.user)
  end

  describe 'GET index' do
    render_views

    subject { get :index, params: { procedure_id: procedure.id } }

    it { expect(subject.status).to eq 200 }
    it { expect(subject.body).to include("Configuration des emails") }
    it { expect(subject.body).to include(Mails::InitiatedMail::DISPLAYED_NAME) }
  end

  describe '#preview' do
    let(:procedure) { create(:procedure, :with_logo, :with_service, administrateur: admin) }

    before do
      sign_in(admin.user)
      get :preview, params: { id: "initiated_mail", procedure_id: procedure.id }
    end

    it { expect(response).to have_http_status(:ok) }

    it 'displays the procedure logo' do
      expect(response.body).to have_css("img[src*='/rails/active_storage/blobs/']")
    end

    it 'displays the action buttons' do
      expect(response.body).to have_link('Consulter mon dossier')
    end

    it 'displays the service in the footer' do
      expect(response.body).to include(procedure.service.nom)
      expect(response.body).to include(procedure.service.telephone)
    end
  end
end
