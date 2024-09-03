# frozen_string_literal: true

describe SamlIdpController do
  before do
    allow_any_instance_of(SamlIdpController).to receive(:validate_saml_request).and_return(valid_saml_request)
  end

  describe '#new' do
    let(:action) { get :new }

    context 'with invalid saml request' do
      let(:valid_saml_request) { false }
      it { expect(action).to have_http_status(:forbidden) }
    end

    context 'with valid saml request' do
      let(:valid_saml_request) { true }

      it { expect(action).to have_http_status(:ok) }
    end
  end
  describe '#create' do
    let(:action) { post :create }

    context 'with invalid saml request' do
      let(:valid_saml_request) { false }
      it { expect(action).to have_http_status(:forbidden) }
    end

    context 'with valid saml request' do
      let(:valid_saml_request) { true }

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
          expect(subject).to receive(:idp_make_saml_response).with(superadmin)
          action
        end
      end
    end
  end
end
