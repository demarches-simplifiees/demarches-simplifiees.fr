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

    it { expect(response.body).to have_css("img[src*='#{procedure.logo.filename}']") }

    it { expect(response.body).to include(procedure.service.nom) }
    it { expect(response.body).to include(procedure.service.telephone) }
  end
end
