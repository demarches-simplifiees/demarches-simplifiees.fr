# frozen_string_literal: true

describe AgentConnect::AgentController, type: :controller do
  describe '#login' do
    let(:uri) { 'https://agent-connect.fr' }
    let(:state) { 'state' }
    let(:nonce) { 'nonce' }

    before do
      expect(AgentConnectService).to receive(:authorization_uri).and_return([uri, state, nonce])
      get :login
    end

    it do
      expect(state_cookie).to eq(state)
      expect(nonce_cookie).to eq(nonce)
      expect(response).to redirect_to(uri)
    end
  end

  describe '#callback' do
    let(:email) { 'i@email.com' }
    let(:original_state) { 'original_state' }
    let(:nonce) { 'nonce' }
    let(:id_token) { 'id_token' }
    subject { get :callback, params: { code: code, state: state } }

    before do
      cookies.encrypted[controller.class::STATE_COOKIE_NAME] = original_state
      cookies.encrypted[controller.class::NONCE_COOKIE_NAME] = nonce
    end

    context 'when the callback code is correct' do
      let(:code) { 'correct' }
      let(:state) { original_state }
      let(:user_info) { { 'sub' => 'sub', 'email' => email, 'given_name' => 'given', 'usual_name' => 'usual' } }
      let(:amr) { [] }

      context 'and user_info returns some info' do
        before do
          expect(AgentConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token, amr])
          Flipper.enable(:agent_connect_2fa)
        end

        context 'and the instructeur use mon_compte_pro' do
          before do
            user_info['idp_id'] = AgentConnect::AgentController::MON_COMPTE_PRO_IDP_ID
            allow(controller).to receive(:sign_in)
          end

          context 'without 2FA' do
            it 'redirects to agent_connect_explanation_2fa_path' do
              subject

              expect(controller).not_to have_received(:sign_in)
              expect(response).to redirect_to(agent_connect_explanation_2fa_path)
              expect(state_cookie).to be_nil
              expect(nonce_cookie).to be_nil
              expect(cookies.encrypted[controller.class::AC_ID_TOKEN_COOKIE_NAME]).to eq(id_token)
            end
          end

          context 'with 2FA' do
            let(:amr) { ['mfa'] }

            it 'creates the user, signs in and redirects to procedure_path' do
              expect { subject }.to change { User.count }.by(1).and change { Instructeur.count }.by(1)

              expect(controller).to have_received(:sign_in)
              expect(User.last.instructeur.agent_connect_information.last.amr).to eq(amr)
            end
          end
        end

        context 'and the instructeur does not have an account yet' do
          before do
            expect(controller).to receive(:sign_in)
          end

          it 'creates the user, signs in and redirects to procedure_path' do
            expect { subject }.to change { User.count }.by(1).and change { Instructeur.count }.by(1)

            last_user = User.last

            expect(last_user.email).to eq(email)
            expect(last_user.confirmed_at).to be_present
            expect(last_user.email_verified_at).to be_present
            expect(last_user.instructeur.agent_connect_id_token).to eq('id_token')
            expect(response).to redirect_to(instructeur_procedures_path)
            expect(state_cookie).to be_nil
            expect(nonce_cookie).to be_nil
          end
        end

        context 'and the instructeur already has an account' do
          let!(:instructeur) { create(:instructeur, email: email) }

          before do
            expect(controller).to receive(:sign_in)
          end

          it 'reuses the account, signs in and redirects to procedure_path' do
            expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)
            instructeur.reload

            expect(instructeur.agent_connect_id_token).to eq('id_token')
            expect(response).to redirect_to(instructeur_procedures_path)
          end

          it "sets email_verified_at" do
            expect { subject }.to change { instructeur.user.reload.email_verified_at }.from(
              nil
            )
          end
        end

        context 'and the instructeur already has an account as a user' do
          let!(:user) { create(:user, email: email) }

          before do
            expect(controller).to receive(:sign_in)
          end

          it 'reuses the account, signs in and redirects to procedure_path' do
            expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(1)

            instructeur = user.reload.instructeur

            expect(instructeur.agent_connect_id_token).to eq('id_token')
            expect(response).to redirect_to(instructeur_procedures_path)
          end
        end
      end

      context 'when the instructeur connects two times with the same domain' do
        before do
          expect(AgentConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token]).twice
          expect(controller).to receive(:sign_in).twice
        end

        it 'creates another agent_connect_information' do
          get :callback, params: { code: code, state: state }
          get :callback, params: { code: code, state: state }

          expect(Instructeur.last.agent_connect_information.count).to eq(1)
        end
      end

      context 'when the instructeur connects two times with different domains' do
        before do
          expect(controller).to receive(:sign_in).twice
        end

        it 'creates another agent_connect_information' do
          expect(AgentConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token])
          get :callback, params: { code: code, state: state }

          expect(AgentConnectService).to receive(:user_info).with(code, nonce).and_return([user_info.merge('sub' => 'sub2'), id_token])
          get :callback, params: { code: code, state: state }

          expect(Instructeur.last.agent_connect_information.pluck(:sub)).to match_array(['sub', 'sub2'])
        end
      end

      context 'but user_info raises and error' do
        before do
          expect(AgentConnectService).to receive(:user_info).and_raise(Rack::OAuth2::Client::Error.new(500, error: 'Unknown'))
        end

        it 'aborts the processus' do
          expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when the callback state is not the original' do
      let(:code) { 'correct' }
      let(:state) { 'another state' }

      before { subject }

      it 'aborts the processus' do
        expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when the callback code is blank' do
      let(:code) { '' }
      let(:state) { original_state }

      it 'aborts the processus' do
        expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe '#logout_from_mcp' do
    let(:id_token) { 'id_token' }
    subject { get :logout_from_mcp }

    before do
      cookies.encrypted[controller.class::AC_ID_TOKEN_COOKIE_NAME] = id_token
    end

    it 'clears the id token cookie and redirects to the agent connect logout url' do
      expect(AgentConnectService).to receive(:logout_url).with(id_token, host_with_port: 'test.host')
        .and_return("https://agent-connect.fr/logout/#{id_token}")

      subject

      expect(cookies.encrypted[controller.class::AC_ID_TOKEN_COOKIE_NAME]).to be_nil
      expect(cookies.encrypted[controller.class::REDIRECT_TO_AC_LOGIN_COOKIE_NAME]).to eq(true)
      expect(response).to redirect_to("https://agent-connect.fr/logout/#{id_token}")
    end

    context 'when the id_token is blank' do
      let(:id_token) { nil }

      it 'clears the cookies and redirects to the root path' do
        subject

        expect(cookies.encrypted[controller.class::REDIRECT_TO_AC_LOGIN_COOKIE_NAME]).to be_nil
        expect(response).to redirect_to(root_path)
      end
    end
  end

  def state_cookie
    cookies.encrypted[controller.class::STATE_COOKIE_NAME]
  end

  def nonce_cookie
    cookies.encrypted[controller.class::NONCE_COOKIE_NAME]
  end
end
