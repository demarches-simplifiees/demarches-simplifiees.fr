require 'spec_helper'

describe Users::SessionsController, type: :controller do
  let(:loged_in_with_france_connect) { 'particulier' }
  let(:user) { create(:user, loged_in_with_france_connect: loged_in_with_france_connect) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '.demo' do
    context 'when server is on env production' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      end
      subject { get :demo }

      it { expect(subject).to redirect_to root_path }

    end
  end

  describe '.create' do
    it { expect(described_class).to be < Sessions::SessionsController }

    describe 'France Connect attribut' do
      before do
        post :create, user: {email: user.email, password: user.password}
        user.reload
      end

      subject { user.loged_in_with_france_connect? }

      it { is_expected.to be_falsey }
    end
  end

  describe '.destroy' do
    before do
      sign_in user
      delete :destroy
    end

    it 'user is sign out' do
      expect(subject.current_user).to be_nil
    end

    it 'loged_in_with_france_connect current_user attribut is nil' do
      user.reload
      expect(user.loged_in_with_france_connect?).to be_falsey
    end


    context 'when user is connect with france connect particulier' do
      let(:loged_in_with_france_connect) { 'particulier' }

      it 'redirect to france connect logout page' do
        expect(response).to redirect_to(FRANCE_CONNECT.particulier_logout_endpoint)
      end
    end

    context 'when user is not connect with france connect' do
      let(:loged_in_with_france_connect) { '' }

      it 'redirect to root page' do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '.new' do
    subject { get :new }

    context 'when procedure_id is not present in user_return_to session params' do
      it { expect(subject.status).to eq 200}
    end

    context 'when procedure_id is present in user_return_to session params' do
      context 'when procedure_id does not exist' do
        before do
          session["user_return_to"] = '?procedure_id=0'
        end

        it { expect(subject.status).to eq 302}
        it { expect(subject).to redirect_to root_path }
      end

      context 'when procedure_id exist' do
        let(:procedure) { create :procedure }

        before do
          session["user_return_to"] = "?procedure_id=#{procedure.id}"
        end

        it { expect(subject.status).to eq 200}
      end
    end
  end
end