describe NewAdministrateur::ProceduresController, type: :controller do
  let(:admin) { create(:administrateur) }

  describe '#apercu' do
    let(:procedure) { create(:procedure) }

    before do
      sign_in admin
      get :apercu, params: { id: procedure.id }
    end

    it { expect(response).to have_http_status(:ok) }
  end
end
