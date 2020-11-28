describe Manager::DemandesController, type: :controller do
  let(:administration) { create(:administration) }

  describe 'GET #index' do
    before do
      sign_in administration
    end

    it "display pending demandes" do
      approved_administrateur = create(:administrateur, email: "approved@example.com")
      pending_demande = { email: 'pending@example.com' }
      demandes = [{ email: approved_administrateur.email }, pending_demande]
      allow(PipedriveService).to receive(:get_demandes).and_return(demandes)

      get :index

      expect(assigns(:pending_demandes)).to eq([pending_demande])
    end
  end
end
