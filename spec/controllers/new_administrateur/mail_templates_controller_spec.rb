describe NewAdministrateur::MailTemplatesController, type: :controller do
  render_views

  let(:admin) { create(:administrateur) }

  describe '#preview' do
    let(:procedure) { create(:procedure, :with_logo, :with_service, administrateur: admin) }

    before do
      sign_in admin
      get :preview, params: { id: "initiated_mail", procedure_id: procedure.id }
    end

    it { expect(response).to have_http_status(:ok) }

    it 'displays the procedure logo' do
      expect(response.body).to have_css("img[src*='#{procedure.logo.filename}']")
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
