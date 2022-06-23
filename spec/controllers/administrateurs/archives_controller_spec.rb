describe Administrateurs::ArchivesController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin }

  describe 'GET #index' do
    subject { get :index, params: { procedure_id: procedure.id } }

    context 'when logged out' do
      it { is_expected.to have_http_status(302) }
    end
    context 'when logged in' do
      before do
        sign_in(admin.user)
      end

      it { is_expected.to have_http_status(200) }
    end
  end
end
