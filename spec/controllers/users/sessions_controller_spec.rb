describe Users::SessionsController, type: :controller do
  let(:email) { 'unique@plop.com' }
  let(:password) { 'my-s3cure-p4ssword' }
  let(:loged_in_with_france_connect) { User.loged_in_with_france_connects.fetch(:particulier) }
  let!(:user) { create(:user, email: email, password: password, loged_in_with_france_connect: loged_in_with_france_connect) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#create' do
    let(:user) { create(:user, email: email, password: password, loged_in_with_france_connect: 'particulier') }
    let(:send_password) { password }
    let(:remember_me) { '0' }

    subject do
      post :create, params: {
        user: {
          email: email,
          password: send_password,
          remember_me: remember_me
        }
      }
    end

    context 'when the credentials are right' do
      it 'signs in' do
        subject

        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq(user)
        expect(user.reload.loged_in_with_france_connect).to be(nil)
        expect(user.reload.remember_created_at).to be_nil
      end

      context 'when remember_me is specified' do
        let(:remember_me) { '1' }

        it 'remembers' do
          subject

          expect(user.reload.remember_created_at).to be_present
        end
      end

      context 'when a previous path was registered' do
        let(:stored_path) { 'a_path' }

        before { controller.store_location_for(:user, stored_path) }

        it 'redirects to that previous path' do
          subject

          expect(response).to redirect_to(stored_path)
        end
      end

      context 'when the user is locked' do
        before { user.lock_access! }

        it 'redirects to new_path' do
          subject

          expect(response).to render_template(:new)
          expect(flash.alert).to eq("Adresse éléctronique ou mot de passe incorrect.")
        end
      end
    end

    context 'when the credentials are wrong' do
      let(:send_password) { 'wrong_password' }

      it 'fails to sign in with bad credentials' do
        subject

        expect(response).to render_template(:new)
        expect(controller.current_user).to be(nil)
      end
    end
  end

  describe '#destroy' do
    let!(:user) { create(:user, email: email, password: password, loged_in_with_france_connect: loged_in_with_france_connect) }

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
    context 'when the instructeur has non other account' do
      let(:instructeur) { create(:instructeur) }
      let!(:good_jeton) { instructeur.create_trusted_device_token }
      let(:jeton) { good_jeton }
      let(:logged) { false }
      let(:valid_token) { true }

      before do
        if logged
          sign_in(instructeur.user)
        end
        allow(controller).to receive(:trust_device)
        allow(controller).to receive(:send_login_token_or_bufferize)
        allow_any_instance_of(TrustedDeviceToken).to receive(:token_valid?).and_return(valid_token)
        post :sign_in_by_link, params: { id: instructeur.id, jeton: jeton }
      end

      context 'when the instructeur is not logged in' do
        context 'when the token is valid' do
          it { is_expected.to redirect_to new_user_session_path }
          it { expect(controller.current_instructeur).to be_nil }
          it { expect(controller).to have_received(:trust_device) }
        end

        context 'when the token is invalid' do
          let(:valid_token) { false }

          it { is_expected.to redirect_to link_sent_path(email: instructeur.email) }
          it { expect(controller.current_instructeur).to be_nil }
          it { expect(controller).not_to have_received(:trust_device) }
          it { expect(controller).to have_received(:send_login_token_or_bufferize) }
        end

        context 'when the token does not exist' do
          let(:jeton) { 'I do not exist' }

          it { is_expected.to redirect_to root_path }
          it { expect(controller.current_instructeur).to be_nil }
          it { expect(controller).not_to have_received(:trust_device) }
          it { expect(controller).not_to have_received(:send_login_token_or_bufferize) }
          it { expect(flash.alert).to eq('Votre lien est invalide.') }
        end
      end

      context 'when the instructeur is logged in' do
        let(:logged) { true }

        context 'when the token is valid' do
          # redirect to root_path, then redirect to instructeur_procedures_path (see root_controller)
          it { is_expected.to redirect_to root_path }
          it { expect(controller.current_instructeur).to eq(instructeur) }
          it { expect(controller).to have_received(:trust_device) }
        end

        context 'when the token is invalid' do
          let(:valid_token) { false }

          it { is_expected.to redirect_to link_sent_path(email: instructeur.email) }
          it { expect(controller.current_instructeur).to eq(instructeur) }
          it { expect(controller).not_to have_received(:trust_device) }
          it { expect(controller).to have_received(:send_login_token_or_bufferize) }
        end
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
        emission_date = Time.zone.now - TrustedDeviceConcern::TRUSTED_DEVICE_PERIOD - 1.minute
        controller.trust_device(emission_date)
      end

      it { is_expected.to be false }
    end

    context 'when the cookie is ok' do
      before { controller.trust_device(Time.zone.now) }

      it { is_expected.to be true }
    end
  end

  describe '#link_sent' do
    render_views

    before { get :link_sent, params: { email: link_email } }

    context 'when the email is legit' do
      let(:link_email) { 'a@a.com' }

      it { expect(response.body).to include(link_email) }
    end

    context 'when the email is evil' do
      [
        'Hello, I am an evil email',
        'a@a%C2%A0evil%C2%A0text%C2%A0with%C2%A0spaces'
      ].each do |evil_attempt|
        let(:link_email) { evil_attempt }

        it { expect(response).to redirect_to(root_path) }
      end
    end
  end
end
