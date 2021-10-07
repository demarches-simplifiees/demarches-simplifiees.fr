describe SamlIdpController do
  describe '#new' do
    let(:action) { get :new }

    context 'without superadmin connected' do
      it { expect(action).to redirect_to root_path }

      it "display alert" do
        action
        expect(flash[:alert]).to eq("Vous n’êtes pas autorisé à accéder à ce service.")
      end
    end

    context 'with superadmin connected' do
      let(:superadmin) { create(:super_admin) }
      before { sign_in superadmin }

      it 'encode saml response' do
        expect(subject).to receive(:encode_SAMLResponse).with(superadmin.email, anything())
        action
      end
    end
  end
end
