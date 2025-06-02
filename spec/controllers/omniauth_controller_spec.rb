# frozen_string_literal: true

describe OmniauthController, type: :controller do
  let(:birthdate) { '20150821' }
  let(:email) { 'EMAIL_from_fc@test.com' }
  let(:provider) { 'google' }

  let(:user_info) do
    {
      france_connect_particulier_id: 'blablabla',
      given_name: 'titi',
      family_name: 'toto',
      birthdate: birthdate,
      birthplace: '1234',
      gender: 'M',
      email_france_connect: email
    }
  end

  describe '#auth' do
    subject { get :login, params: { provider: provider } }

    it { is_expected.to have_http_status(:redirect) }
  end

  describe '#callback' do
    let(:code) { 'plop' }

    subject { get :callback, params: { code: code, provider: provider } }

    context 'when params are missing' do
      subject { get :callback, params: { provider: provider } }

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when param code is missing' do
      let(:code) { nil }

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when param code is empty' do
      let(:code) { '' }

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when code is correct' do
      before do
        allow(OmniAuthService).to receive(:retrieve_user_informations)
          .and_return(FranceConnectInformation.new(user_info))
      end

      context 'when france_connect_particulier_id exists in database' do
        let!(:fci) { FranceConnectInformation.create!(user_info.merge(user_id: fc_user&.id)) }

        context 'and is linked to an user' do
          let(:fc_user) { create(:user, email: 'associated_user@a.com') }

          it { expect { subject }.not_to change { FranceConnectInformation.count } }

          it 'signs in with the fci associated user' do
            subject
            expect(controller.current_user).to eq(fc_user)
            expect(fc_user.reload.loged_in_with_france_connect).to eq(User.loged_in_with_france_connects.fetch(provider))
          end

          context 'and the user has a stored location' do
            let(:stored_location) { '/plip/plop' }
            before { controller.store_location_for(:user, stored_location) }

            it { is_expected.to redirect_to(stored_location) }
          end
        end

        context 'and is linked an instructeur' do
          let(:fc_user) { create(:instructeur, email: 'another_email@a.com').user }

          before { subject }

          it do
            expect(response).to redirect_to(new_user_session_path)
            expect(flash[:alert]).to be_present
          end
        end

        context 'and is not linked to an user' do
          let(:fc_user) { nil }

          context 'and no user with the same email exists' do
            it 'creates an user with the same email and log in' do
              expect { subject }.to change { User.count }.by(1)

              user = User.last

              expect(user.email).to eq(email.downcase)
              expect(controller.current_user).to eq(user)
              expect(response).to redirect_to(root_path)
            end
          end

          context 'and an user with the same email exists' do
            let!(:preexisting_user) { create(:user, email: email) }

            it 'redirects to the merge process' do
              expect { subject }.not_to change { User.count }

              expect(response).to redirect_to(omniauth_merge_path(provider, fci.reload.merge_token))
            end
          end
          context 'and an instructeur with the same email exists' do
            let!(:preexisting_user) { create(:instructeur, email: email) }

            it 'redirects to the merge process' do
              expect { subject }.not_to change { User.count }

              expect(response).to redirect_to(new_user_session_path)
              expect(flash[:alert]).to eq(I18n.t('errors.messages.omniauth.forbidden_html', reset_link: new_user_password_path, provider: I18n.t("omniauth.provider.#{provider}")))
            end
          end
        end
      end

      context 'when france_connect_particulier_id does not exist in database' do
        it { expect { subject }.to change { FranceConnectInformation.count }.by(1) }

        describe 'FranceConnectInformation attributs' do
          let(:stored_fci) { FranceConnectInformation.last }

          before { subject }

          it { expect(stored_fci).to have_attributes(user_info.merge(birthdate: Time.zone.parse(birthdate).to_datetime)) }
        end

        it { is_expected.to redirect_to(root_path) }
      end
    end

    context 'when code is not correct' do
      before do
        allow(OmniAuthService).to receive(:retrieve_user_informations) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
        subject
      end

      it {
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be_present
      }
    end
  end

  RSpec.shared_examples "a method that needs a valid merge token" do
    context 'when the merge token is invalid' do
      before do
        stub_const("APPLICATION_NAME", "demarches-simplifiees.fr")
        merge_token
        fci.update(merge_token_created_at: 2.years.ago)
      end

      it do
        if format == :js
          subject
          expect(response.body).to eq("window.location.href='/'")
        else
          expect(subject).to redirect_to root_path
        end
        expect(flash.alert).to eq('Le délai pour fusionner les comptes Google et demarches-simplifiees.fr est expiré. Veuillez recommencer la procédure pour fusionner les comptes.')
      end
    end
  end

  describe '#merge' do
    let(:fci) { FranceConnectInformation.create!(user_info) }
    let(:merge_token) { fci.create_merge_token! }
    let(:format) { :html }

    subject { get :merge, params: { provider: provider, merge_token: merge_token } }

    context 'when the merge token is valid' do
      it { expect(subject).to have_http_status(:ok) }
    end

    it_behaves_like "a method that needs a valid merge token"

    context 'when the merge token does not exist' do
      let(:merge_token) { 'i do not exist' }

      before do
        stub_const("APPLICATION_NAME", "demarches-simplifiees.fr")
      end

      it do
        expect(subject).to redirect_to root_path
        expect(flash.alert).to eq('Le délai pour fusionner les comptes Google et demarches-simplifiees.fr est expiré. Veuillez recommencer la procédure pour fusionner les comptes.')
      end
    end
  end

  describe '#merge_with_existing_account' do
    let(:fci) { FranceConnectInformation.create!(user_info) }
    let(:merge_token) { fci.create_merge_token! }
    let(:email) { 'EXISTING_account@a.com ' }
    let(:password) { SECURE_PASSWORD }
    let(:format) { :turbo_stream }

    subject { post :merge_with_existing_account, params: { merge_token:, email:, password:, provider: }, format: }

    it_behaves_like "a method that needs a valid merge token"

    context 'when the user is not found' do
      it 'does not log' do
        subject
        fci.reload

        expect(fci.user).to be_nil
        expect(fci.merge_token).not_to be_nil
        expect(controller.current_user).to be_nil
      end
    end

    context 'when the credentials are ok' do
      let!(:user) { create(:user, email: email, password: password) }

      it 'merges the account, signs in, and delete the merge token' do
        subject
        fci.reload

        expect(fci.user).to eq(user)
        expect(fci.merge_token).to be_nil
        expect(controller.current_user).to eq(user)
      end

      context 'but the targeted user is an instructeur' do
        let!(:user) { create(:instructeur, email: email, password: password).user }

        it 'redirects to the root page' do
          subject
          fci.reload

          expect(fci.user).to be_nil
          expect(fci.merge_token).not_to be_nil
          expect(controller.current_user).to be_nil
        end
      end
    end

    context 'when the credentials are not ok' do
      let!(:user) { create(:user, email: email, password: 'another password #$21$%%') }

      it 'increases the failed attempts counter' do
        subject
        fci.reload

        expect(fci.user).to be_nil
        expect(fci.merge_token).not_to be_nil
        expect(controller.current_user).to be_nil
        expect(user.reload.failed_attempts).to eq(1)
      end
    end
  end

  describe '#mail_merge_with_existing_account' do
    let(:fci) { FranceConnectInformation.create!(user_info) }
    let!(:merge_token) { fci.create_merge_token! }

    context 'when the merge_token is ok and the user is found' do
      subject { post :mail_merge_with_existing_account, params: { merge_token: fci.merge_token, provider: } }

      let!(:user) { create(:user, email: email, password: SECURE_PASSWORD) }

      it 'merges the account, signs in, and delete the merge token' do
        subject
        fci.reload

        expect(fci.user).to eq(user)
        expect(fci.merge_token).to be_nil
        expect(controller.current_user).to eq(user)
        expect(flash[:notice]).to eq("Les comptes Google et #{APPLICATION_NAME} sont à présent fusionnés")
      end

      context 'but the targeted user is an instructeur' do
        let!(:user) { create(:instructeur, email: email, password: SECURE_PASSWORD).user }

        it 'redirects to the new session' do
          subject
          expect(FranceConnectInformation.exists?(fci.id)).to be_falsey
          expect(controller.current_user).to be_nil
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to eq(I18n.t('errors.messages.omniauth.forbidden_html', reset_link: new_user_password_path, provider: I18n.t("omniauth.provider.#{provider}")))
        end
      end
    end

    context 'when the merge_token is not ok' do
      subject { post :mail_merge_with_existing_account, params: { merge_token: 'ko', provider: } }

      let!(:user) { create(:user, email: email) }

      it 'increases the failed attempts counter' do
        subject
        fci.reload

        expect(fci.user).to be_nil
        expect(fci.merge_token).not_to be_nil
        expect(controller.current_user).to be_nil
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#merge_with_new_account' do
    let(:fci) { FranceConnectInformation.create!(user_info) }
    let(:merge_token) { fci.create_merge_token! }
    let(:email) { ' Account@a.com ' }
    let(:format) { :turbo_stream }

    subject { post :merge_with_new_account, params: { merge_token:, email:, provider: }, format: format }

    it_behaves_like "a method that needs a valid merge token"

    context 'when the email does not belong to any user' do
      it 'creates the account, signs in, and delete the merge token' do
        subject
        fci.reload

        expect(fci.user.email).to eq(email.downcase.strip)
        expect(fci.merge_token).to be_nil
        expect(controller.current_user).to eq(fci.user)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when an account with the same email exists' do
      let!(:user) { create(:user, email: email) }

      render_views

      it 'asks for the corresponding password' do
        subject
        fci.reload

        expect(fci.user).to be_nil
        expect(fci.merge_token).not_to be_nil
        expect(controller.current_user).to be_nil

        expect(response.body).to include('entrez votre mot de passe')
      end
    end
  end

  describe '#resend_and_renew_merge_confirmation' do
    let(:fci) { FranceConnectInformation.create!(user_info) }
    let(:merge_token) { fci.create_merge_token! }
    it 'renew token' do
      expect { post :resend_and_renew_merge_confirmation, params: { merge_token:, provider: } }.to change { fci.reload.merge_token }
      expect(response).to redirect_to(omniauth_merge_path(provider, fci.reload.merge_token))
    end
  end
end
