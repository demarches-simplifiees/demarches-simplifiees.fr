describe Users::TransfersController, type: :controller do
  let(:sender_user) { create(:user) }
  let(:recipient_user) { create(:user) }
  let(:dossier) { create(:dossier, user: sender_user) }

  describe 'DELETE destroy' do
    let(:dossier_transfert) { DossierTransfer.initiate(recipient_user.email, [dossier]) }

    subject { delete :destroy, params: { id: dossier_transfert.id } }

    before do
      sign_in(recipient_user)
    end

    it { expect { subject }.not_to raise_error }

    it "deletes dossier transfert" do
      subject
      expect { dossier_transfert.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST create" do
    subject { post :create, params: { dossier_transfer: { email: email, dossier: dossier.id } } }

    before do
      sign_in(sender_user)
      subject
    end

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
