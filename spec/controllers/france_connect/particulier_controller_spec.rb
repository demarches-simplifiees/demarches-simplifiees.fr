# frozen_string_literal: true

describe FranceConnect::ParticulierController, type: :controller do
  let(:birthdate) { '20150821' }
  let(:email) { 'EMAIL_from_fc@test.com' }

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
    subject { get :login }

    it { is_expected.to have_http_status(:redirect) }
  end

  describe '#callback' do
    let(:code) { 'plop' }

    subject { get :callback, params: { code: code } }

    context 'when params are missing' do
      subject { get :callback }

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
        allow(FranceConnectService).to receive(:retrieve_user_informations_particulier)
          .and_return(FranceConnectInformation.new(user_info))
      end

      context 'when france_connect_particulier_id exists in database' do
        let!(:fci) { FranceConnectInformation.create!(user_info.merge(user_id: fc_user&.id)) }

        context 'and is linked to an user' do
          let(:fc_user) { create(:user, email: 'associated_user@a.com') }

          it { expect { subject }.not_to change { FranceConnectInformation.count } }
          it { expect { subject }.to change { fc_user.reload.last_sign_in_at } }

          it 'signs in with the fci associated user' do
            subject
            expect(controller.current_user).to eq(fc_user)
            expect(fc_user.reload.loged_in_with_france_connect).to eq(User.loged_in_with_france_connects.fetch(:particulier))
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
            it 'render the choose email template to select good email' do
              expect { subject }.to change { User.count }.by(0)
              expect(subject).to render_template(:choose_email)
            end
          end

          context 'and an user with the same email exists' do
            let!(:preexisting_user) { create(:user, email: email) }

            it 'renders the merge page' do
              expect { subject }.not_to change { User.count }

              expect(response).to render_template(:merge)
            end
          end
          context 'and an instructeur with the same email exists' do
            let!(:preexisting_user) { create(:instructeur, email: email) }

            it 'redirects to the login path' do
              expect { subject }.not_to change { User.count }

              expect(response).to redirect_to(new_user_session_path)
              expect(flash[:alert]).to eq(I18n.t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path))
            end
          end
        end
      end

      context 'when france_connect_particulier_id does not exist in database' do
        it { expect { subject }.to change { FranceConnectInformation.count }.by(1) }

        it { is_expected.to render_template(:choose_email) }
      end
    end

    context 'when code is not correct' do
      before do
        allow(FranceConnectService).to receive(:retrieve_user_informations_particulier) { raise Rack::OAuth2::Client::Error.new(500, error: 'Unknown') }
        subject
      end

      it { expect(response).to redirect_to(new_user_session_path) }

      it { expect(flash[:alert]).to be_present }
    end
  end

  describe '#merge_using_fc_email' do
    subject { post :merge_using_fc_email, params: { merge_token: merge_token } }

    let!(:fci) { FranceConnectInformation.create!(user_info) }
    let(:merge_token) { fci.create_merge_token! }

    before do
      allow(UserMailer).to receive_message_chain(:custom_confirmation_instructions, :deliver_later)
    end

    context 'when the merge token is valid' do
      it do
        expect(User.last.email).not_to eq(email.downcase)

        subject

        user = User.last

        expect(user.email).to eq(email.downcase)
        expect(UserMailer).to have_received(:custom_confirmation_instructions).with(user, user.confirmation_token)
        expect(user.email_verified_at).to be_nil
        expect(fci.reload.merge_token).to be_nil
        expect(response).to render_template(:confirmation_sent)
      end
    end

    context 'when the merge token is invalid' do
      let(:merge_token) { 'invalid_token' }

      it 'redirects to root_path with an alert' do
        subject
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Le délai pour fusionner les comptes FranceConnect et demarches-simplifiees.fr est expiré. Veuillez recommencer la procédure pour vous fusionner les comptes.")
      end
    end

    context 'when @fci is not valid for merge' do
      before do
        merge_token
        fci.update!(merge_token_created_at: 2.years.ago)
      end

      it 'redirects to root_path with an alert' do
        subject

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Le délai pour fusionner les comptes FranceConnect et demarches-simplifiees.fr est expiré. Veuillez recommencer la procédure pour vous fusionner les comptes.')
      end
    end
  end

  describe '#confirm_email' do
    let!(:user) { create(:user) }
    let!(:fci) { create(:france_connect_information, user: user) }

    before { fci.send_custom_confirmation_instructions }

    context 'when the confirmation token is valid' do
      before do
        get :confirm_email, params: { token: user.confirmation_token }
        user.reload
      end

      it do
        expect(user.email_verified_at).to be_present
        expect(user.confirmation_token).to be_nil

        expect(response).to redirect_to(root_path(user))
        expect(flash[:notice]).to eq('Votre email est bien vérifié')
      end
    end

    context 'when invites are pending' do
      let!(:invite) { create(:invite, email: user.email, user: nil) }

      it 'links pending invites' do
        get :confirm_email, params: { token: user.confirmation_token }
        invite.reload
        expect(invite.user).to eq(user)
      end
    end

    context 'when the confirmation token is expired' do
      let!(:expired_user_confirmation) do
        create(:user, confirmation_token: 'expired_token', confirmation_sent_at: 3.days.ago)
      end

      it 'redirects to root path with an alert when FranceConnectInformation is not found' do
        get :confirm_email, params: { token: 'expired_token' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t('france_connect.particulier.flash.confirmation_mail_resent_error'))
      end

      context 'when FranceConnectInformation exists' do
        let!(:france_connect_information) do
          create(:france_connect_information, user: expired_user_confirmation)
        end

        before do
          allow(UserMailer).to receive_message_chain(:custom_confirmation_instructions, :deliver_later)
        end

        it 'resends the confirmation email and redirects to root path with a notice' do
          get :confirm_email, params: { token: 'expired_token' }

          expect(UserMailer).to have_received(:custom_confirmation_instructions)
            .with(expired_user_confirmation, expired_user_confirmation.reload.confirmation_token)

          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq(I18n.t('france_connect.particulier.flash.confirmation_mail_resent'))
        end
      end
    end

    context 'when a different user is signed in' do
      let!(:expired_user_confirmation) do
        create(:user, confirmation_token: 'expired_token', confirmation_sent_at: 3.days.ago)
      end

      let(:another_user) { create(:user) }

      before { sign_in(another_user) }

      it 'signs out the current user and redirects to sign in path' do
        expect_any_instance_of(FranceConnectInformation).not_to receive(:send_custom_confirmation_instructions)
        expect(controller).to receive(:sign_out).with(:user)

        get :confirm_email, params: { token: 'expired_token' }

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq(I18n.t('france_connect.particulier.flash.redirect_new_user_session'))
      end
    end
  end

  describe '#set_user_by_confirmation_token' do
    let(:current_user) { create(:user) }
    let!(:confirmation_user) { create(:user, confirmation_token: 'valid_token') }

    before { sign_in current_user }

    it 'signs out current user and redirects to new session path when users do not match' do
      expect(controller).to receive(:sign_out).with(:user)

      get :confirm_email, params: { token: 'valid_token' }

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq(I18n.t('france_connect.particulier.flash.redirect_new_user_session'))
    end

    context 'when user is not found' do
      it 'redirects to root path with user not found alert' do
        get :confirm_email, params: { token: 'invalid_token' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t('france_connect.particulier.flash.user_not_found'))
      end
    end
  end

  RSpec.shared_examples "a method that needs a valid merge token" do
    context 'when the merge token is invalid' do
      before do
        allow(Current).to receive(:application_name).and_return('demarches-simplifiees.fr')
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
        expect(flash.alert).to eq('Le délai pour fusionner les comptes FranceConnect et demarches-simplifiees.fr est expiré. Veuillez recommencer la procédure pour fusionner les comptes.')
      end
    end
  end

  describe '#merge_using_password' do
    let(:fci) { FranceConnectInformation.create!(user_info) }
    let(:merge_token) { fci.create_merge_token! }
    let(:email) { 'EXISTING_account@a.com ' }
    let(:password) { SECURE_PASSWORD }
    let(:format) { :turbo_stream }

    subject { post :merge_using_password, params: { merge_token: merge_token, password: password }, format: format }

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

          expect { fci.reload }.to raise_error(ActiveRecord::RecordNotFound)

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

  describe '#merge_using_email_link' do
    let(:fci) { FranceConnectInformation.create!(user_info) }
    let!(:email_merge_token) { fci.create_email_merge_token! }

    context 'when the merge_token is ok and the user is found' do
      subject do
        post :merge_using_email_link, params: { email_merge_token: }
      end

      before do
        allow(Current).to receive(:application_name).and_return('demarches-simplifiees.fr')
        fci.update!(requested_email: email.downcase)
      end

      let!(:user) { create(:user, email:, password: 'abcdefgh') }

      it 'merges the account, signs in, and delete the merge token' do
        subject
        fci.reload

        expect(fci.user).to eq(user)
        expect(fci.merge_token).to be_nil
        expect(fci.email_merge_token).to be_nil
        expect(controller.current_user).to eq(user)
        expect(flash[:notice]).to eq("Les comptes FranceConnect et #{Current.application_name} sont à présent fusionnés")
      end

      context 'but the targeted user is an instructeur' do
        let!(:user) { create(:instructeur, email: email, password: SECURE_PASSWORD).user }

        it 'redirects to the new session' do
          subject
          expect(FranceConnectInformation.exists?(fci.id)).to be_falsey
          expect(controller.current_user).to be_nil
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to eq(I18n.t('errors.messages.france_connect.forbidden_html', reset_link: new_user_password_path))
        end
      end
    end
  end

  describe '#send_email_merge_request' do
    let(:fci) { FranceConnectInformation.create!(user_info) }
    let(:merge_token) { fci.create_merge_token! }
    let(:email) { 'requested_email@.a.com' }

    subject { post :send_email_merge_request, params: { merge_token: merge_token, email: } }

    it 'renew token' do
      allow(UserMailer).to receive_message_chain(:france_connect_merge_confirmation, :deliver_later)
      subject

      fci.reload
      expect(fci.requested_email).to eq(email)
      expect(fci.email_merge_token).to be_present

      expect(UserMailer).to have_received(:france_connect_merge_confirmation).with(email, fci.email_merge_token, fci.email_merge_token_created_at)

      expect(response).to redirect_to(root_path)
    end
  end
end
