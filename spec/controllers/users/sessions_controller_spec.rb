require 'spec_helper'

describe Users::SessionsController, type: :controller do
  let(:loged_in_with_france_connect) { User.loged_in_with_france_connects.fetch(:particulier) }
  let(:user) { create(:user, loged_in_with_france_connect: loged_in_with_france_connect) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#create' do
    it { expect(described_class).to be < Sessions::SessionsController }

    describe 'France Connect attribut' do
      before do
        post :create, params: { user: { email: user.email, password: user.password } }
        user.reload
      end

      subject { user.loged_in_with_france_connect? }

      it { is_expected.to be_falsey }
    end

    context "unified login" do
      let(:email) { 'unique@plop.com' }
      let(:password) { 'un super mot de passe' }

      let(:user) { create(:user, email: email, password: password) }
      let(:gestionnaire) { create(:gestionnaire, email: email, password: password) }
      let(:administrateur) { create(:administrateur, email: email, password: password) }

      it 'signs user in' do
        post :create, params: { user: { email: user.email, password: user.password } }
        expect(@response.redirect?).to be(true)
        expect(subject.current_user).to eq(user)
        expect(subject.current_gestionnaire).to be(nil)
        expect(subject.current_administrateur).to be(nil)
        expect(user.reload.loged_in_with_france_connect).to be(nil)
      end

      it 'signs gestionnaire in' do
        post :create, params: { user: { email: gestionnaire.email, password: gestionnaire.password } }
        expect(@response.redirect?).to be(true)
        expect(subject.current_user).to be(nil)
        expect(subject.current_gestionnaire).to eq(gestionnaire)
        expect(subject.current_administrateur).to be(nil)
      end

      it 'signs administrateur in' do
        post :create, params: { user: { email: administrateur.email, password: administrateur.password } }
        expect(@response.redirect?).to be(true)
        expect(subject.current_user).to be(nil)
        expect(subject.current_gestionnaire).to be(nil)
        expect(subject.current_administrateur).to eq(administrateur)
      end

      context {
        before do
          user
          gestionnaire
        end

        it 'signs user + gestionnaire + administrateur in' do
          post :create, params: { user: { email: administrateur.email, password: administrateur.password } }
          expect(@response.redirect?).to be(true)
          expect(subject.current_user).to eq(user)
          expect(subject.current_gestionnaire).to eq(gestionnaire)
          expect(subject.current_administrateur).to eq(administrateur)
          expect(user.reload.loged_in_with_france_connect).to be(nil)
        end
      }

      it 'fails to sign in with bad credentials' do
        post :create, params: { user: { email: user.email, password: 'wrong_password' } }
        expect(@response.unauthorized?).to be(true)
        expect(subject.current_user).to be(nil)
        expect(subject.current_gestionnaire).to be(nil)
        expect(subject.current_administrateur).to be(nil)
      end

      context 'with different passwords' do
        let!(:gestionnaire) { create(:gestionnaire, email: email, password: 'mot de passe complexe') }
        let!(:administrateur) { create(:administrateur, email: email, password: 'mot de passe complexe') }

        before do
          user
        end

        it 'should sync passwords on login' do
          post :create, params: { user: { email: email, password: password } }
          gestionnaire.reload
          administrateur.reload
          expect(user.valid_password?(password)).to be(true)
          expect(gestionnaire.valid_password?(password)).to be(true)
          expect(administrateur.valid_password?(password)).to be(true)
        end
      end
    end
  end

  describe '#destroy' do
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
      let(:loged_in_with_france_connect) { User.loged_in_with_france_connects.fetch(:particulier) }

      it 'redirect to france connect logout page' do
        expect(response).to redirect_to(FRANCE_CONNECT[:particulier][:logout_endpoint])
      end
    end

    context 'when user is not connect with france connect' do
      let(:loged_in_with_france_connect) { '' }

      it 'redirect to root page' do
        expect(response).to redirect_to(root_path)
      end
    end

    context "when associated gestionnaire" do
      let(:user) { create(:user, email: 'unique@plop.com', password: 'password') }
      let(:gestionnaire) { create(:gestionnaire, email: 'unique@plop.com', password: 'password') }

      it 'signs user out' do
        sign_in user
        delete :destroy
        expect(@response.redirect?).to be(true)
        expect(subject.current_user).to be(nil)
      end

      it 'signs gestionnaire out' do
        sign_in gestionnaire
        delete :destroy
        expect(@response.redirect?).to be(true)
        expect(subject.current_gestionnaire).to be(nil)
      end

      it 'signs user + gestionnaire out' do
        sign_in user
        sign_in gestionnaire
        delete :destroy
        expect(@response.redirect?).to be(true)
        expect(subject.current_user).to be(nil)
        expect(subject.current_gestionnaire).to be(nil)
      end

      it 'signs user out from france connect' do
        user.update(loged_in_with_france_connect: User.loged_in_with_france_connects.fetch(:particulier))
        sign_in user
        delete :destroy
        expect(@response.headers["Location"]).to eq(FRANCE_CONNECT[:particulier][:logout_endpoint])
      end

      context "when associated administrateur" do
        let(:administrateur) { create(:administrateur, email: 'unique@plop.com') }

        it 'signs user + gestionnaire + administrateur out' do
          sign_in user
          sign_in gestionnaire
          sign_in administrateur
          delete :destroy
          expect(@response.redirect?).to be(true)
          expect(subject.current_user).to be(nil)
          expect(subject.current_gestionnaire).to be(nil)
          expect(subject.current_administrateur).to be(nil)
        end
      end
    end
  end

  describe '#new' do
    subject { get :new }

    context 'when procedure_id is not present in user_return_to session params' do
      it { expect(subject.status).to eq 200 }
    end

    context 'when procedure_id is present in user_return_to session params' do
      context 'when procedure_id does not exist' do
        before do
          session["user_return_to"] = '?procedure_id=0'
        end

        it { expect(subject.status).to eq 302 }
        it { expect(subject).to redirect_to root_path }
      end

      context 'when procedure is not published' do
        let(:procedure) { create :procedure }
        before do
          session["user_return_to"] = "?procedure_id=#{procedure.id}"
        end

        it { expect(subject.status).to eq 302 }
        it { expect(subject).to redirect_to root_path }
      end

      context 'when procedure_id exist' do
        let(:procedure) { create :procedure, :published }

        before do
          session["user_return_to"] = "?procedure_id=#{procedure.id}"
        end

        it { expect(subject.status).to eq 200 }
      end
    end
  end
end
