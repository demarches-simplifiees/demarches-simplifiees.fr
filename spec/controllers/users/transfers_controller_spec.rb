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

  describe "POST create" do
    subject { post :create, params: { dossier_transfer: { email: email, dossier: dossier.id } } }

    before { subject }

    context "with valid email" do
      let(:email) { "test@rspec.net" }

      it { expect(DossierTransfer.last.email).to eq(email) }
      it { expect(DossierTransfer.last.dossiers).to eq([dossier]) }
    end

    context 'with upper case email' do
      let(:email) { "Test@rspec.net" }
      it { expect(DossierTransfer.last.email).to eq(email.strip.downcase) }
    end

    shared_examples 'email error' do
      it { expect { subject }.not_to change { DossierTransfer.count } }
      it { expect(flash.alert).to match([/invalide/]) }
      it { is_expected.to redirect_to transferer_dossier_path(dossier.id) }
    end

    context "when email is empty" do
      let(:email) { "" }
      it_behaves_like 'email error'
    end

    context "when email is invalid" do
      let(:email) { "not-an-email" }
      it_behaves_like 'email error'
    end
  end
end
