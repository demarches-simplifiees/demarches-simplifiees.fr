describe Users::SessionsController, type: :controller do
  let(:email) { 'unique@plop.com' }
  let(:password) { 'un super mot de passe' }
  let(:loged_in_with_france_connect) { User.loged_in_with_france_connects.fetch(:particulier) }
  let!(:user) { create(:user, email: email, password: password, loged_in_with_france_connect: loged_in_with_france_connect) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#create' do
    context "when the user is also a gestionnaire and an administrateur" do
      let!(:administrateur) { create(:administrateur, :with_admin_trusted_device, email: email, password: password) }
      let(:gestionnaire) { administrateur.gestionnaire }
      let(:trusted_device) { true }
      let(:send_password) { password }

      before do
        allow(controller).to receive(:trusted_device?).and_return(trusted_device)
        allow(GestionnaireMailer).to receive(:send_login_token).and_return(double(deliver_later: true))
      end

      subject do
        post :create, params: { user: { email: email, password: send_password } }
        user.reload
      end

      context 'when the device is not trusted' do
        let(:trusted_device) { false }

        it 'redirects to the confirmation link path' do
          subject

          expect(controller).to redirect_to link_sent_path(email: email)

          # do not know why, should be test related
          expect(controller.current_user).to eq(user)

          expect(controller.current_gestionnaire).to be(nil)
          expect(controller.current_administrateur).to be(nil)
          expect(user.loged_in_with_france_connect).to be(nil)
          expect(GestionnaireMailer).to have_received(:send_login_token)
        end

        context 'and the user try to connect multiple times in a short period' do
          before do
            allow_any_instance_of(Gestionnaire).to receive(:young_login_token?).and_return(true)
            allow(GestionnaireMailer).to receive(:send_login_token)
          end

          it 'does not renew nor send a new login token' do
            subject

            expect(GestionnaireMailer).not_to have_received(:send_login_token)
          end
        end
      end

      context 'when the device is trusted' do
        it 'signs in as user, gestionnaire and adminstrateur' do
          subject

          expect(response.redirect?).to be(true)
          expect(controller).not_to redirect_to link_sent_path(email: email)
          # TODO when signing in as non-administrateur, and not starting a demarche, log in to gestionnaire path
          # expect(controller).to redirect_to gestionnaire_procedures_path

          expect(controller.current_user).to eq(user)
          expect(controller.current_gestionnaire).to eq(gestionnaire)
          expect(controller.current_administrateur).to eq(administrateur)
          expect(user.loged_in_with_france_connect).to be(nil)
          expect(GestionnaireMailer).not_to have_received(:send_login_token)
        end
      end

      context 'when the credentials are wrong' do
        let(:send_password) { 'wrong_password' }

        it 'fails to sign in with bad credentials' do
          subject

          expect(response.unauthorized?).to be(true)
          expect(controller.current_user).to be(nil)
          expect(controller.current_gestionnaire).to be(nil)
          expect(controller.current_administrateur).to be(nil)
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
      expect(user.loged_in_with_france_connect.present?).to be_falsey
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
    end

    context "when associated administrateur" do
      let(:administrateur) { create(:administrateur, email: 'unique@plop.com') }

      it 'signs user + gestionnaire + administrateur out' do
        sign_in user
        sign_in administrateur.gestionnaire
        sign_in administrateur
        delete :destroy
        expect(@response.redirect?).to be(true)
        expect(subject.current_user).to be(nil)
        expect(subject.current_gestionnaire).to be(nil)
        expect(subject.current_administrateur).to be(nil)
      end
    end
  end

  describe '#new' do
    subject { get :new }

    it { expect(subject.status).to eq 200 }

    context 'when a procedure location has been stored' do
      let(:procedure) { create :procedure, :published }

      before do
        controller.store_location_for(:user, commencer_path(path: procedure.path))
      end

      it 'makes the saved procedure available' do
        expect(subject.status).to eq 200
        expect(assigns(:procedure)).to eq procedure
      end
    end
  end

  describe '#sign_in_by_link' do
    context 'when the gestionnaire has non other account' do
      let(:gestionnaire) { create(:gestionnaire) }
      let!(:good_jeton) { gestionnaire.login_token! }

      before do
        allow(controller).to receive(:trust_device)
        post :sign_in_by_link, params: { id: gestionnaire.id, jeton: jeton }
      end

      context 'when the token is valid' do
        let(:jeton) { good_jeton }

        # TODO when the gestionnaire has no other account, and the token is valid, and the user signing in was not starting a demarche,
        # redirect to root_path, then redirect to gestionnaire_procedures_path (see root_controller)
        it { is_expected.to redirect_to root_path }
        it { expect(controller.current_gestionnaire).to eq(gestionnaire) }
        it { expect(controller).to have_received(:trust_device) }
      end

      context 'when the token is invalid' do
        let(:jeton) { 'invalid_token' }

        it { is_expected.to redirect_to new_user_session_path }
        it { expect(controller.current_gestionnaire).to be_nil }
        it { expect(controller).not_to have_received(:trust_device) }
      end
    end

    context 'when the gestionnaire has an user and admin account' do
      let(:email) { 'unique@plop.com' }
      let(:password) { 'un super mot de passe' }

      let!(:user) { create(:user, email: email, password: password) }
      let!(:administrateur) { create(:administrateur, email: email, password: password) }
      let(:gestionnaire) { administrateur.gestionnaire }

      before do
        post :sign_in_by_link, params: { id: gestionnaire.id, jeton: jeton }
      end

      context 'when the token is valid' do
        let(:jeton) { gestionnaire.login_token! }

        it { expect(controller.current_gestionnaire).to eq(gestionnaire) }
        it { expect(controller.current_administrateur).to eq(administrateur) }
        it { expect(controller.current_user).to eq(user) }
      end
    end
  end

  describe '#trust_device and #trusted_device?' do
    subject { controller.trusted_device? }

    context 'when the trusted cookie is not present' do
      it { is_expected.to be false }
    end

    context 'when the cookie is outdated' do
      before do
        Timecop.freeze(Time.zone.now - TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD - 1.minute)
        controller.trust_device
        Timecop.return
      end

      it { is_expected.to be false }
    end

    context 'when the cookie is ok' do
      before { controller.trust_device }

      it { is_expected.to be true }
    end
  end
end
