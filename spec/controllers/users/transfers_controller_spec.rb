describe Users::TransfersController, type: :controller do
  let(:user) { create(:user) }
  let(:dossier) { create(:dossier, user: user) }

  before { sign_in(user) }

  describe 'DELETE destroy' do
    let(:dossier_transfert) { DossierTransfer.initiate(user.email, [dossier]) }

    before do
      delete :destroy, params: { id: dossier_transfert.id }
    end

    it { expect { dossier_transfert.reload }.to raise_error(ActiveRecord::RecordNotFound) }
  end
end
