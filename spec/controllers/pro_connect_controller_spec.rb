# frozen_string_literal: true

describe ProConnectController, type: :controller do
  describe '#login' do
    let(:uri) { 'https://www.proconnect.gouv.fr' }
    let(:state) { 'state' }
    let(:nonce) { 'nonce' }

    before do
      expect(ProConnectService).to receive(:authorization_uri).and_return([uri, state, nonce])
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
          expect(ProConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token, amr])
          Flipper.enable(:agent_connect_2fa)
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
          expect(ProConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token]).twice
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
          expect(ProConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token])
          get :callback, params: { code: code, state: state }

          expect(ProConnectService).to receive(:user_info).with(code, nonce).and_return([user_info.merge('sub' => 'sub2'), id_token])
          get :callback, params: { code: code, state: state }

          expect(Instructeur.last.agent_connect_information.pluck(:sub)).to match_array(['sub', 'sub2'])
        end
      end

      context 'but user_info raises and error' do
        before do
          expect(ProConnectService).to receive(:user_info).and_raise(Rack::OAuth2::Client::Error.new(500, error: 'Unknown'))
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

  def state_cookie
    cookies.encrypted[controller.class::STATE_COOKIE_NAME]
  end

  def nonce_cookie
    cookies.encrypted[controller.class::NONCE_COOKIE_NAME]
  end
end
