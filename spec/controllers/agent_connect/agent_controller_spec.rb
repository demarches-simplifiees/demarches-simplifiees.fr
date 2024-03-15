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
    subject { get :callback, params: { code: code, state: state } }

    before do
      cookies.encrypted[controller.class::STATE_COOKIE_NAME] = original_state
      cookies.encrypted[controller.class::NONCE_COOKIE_NAME] = nonce
    end

    context 'when the callback code is correct' do
      let(:code) { 'correct' }
      let(:state) { original_state }
      let(:user_info) { { 'sub' => 'sub', 'email' => ' I@email.com', 'given_name' => 'given', 'usual_name' => 'usual' } }

      context 'and user_info returns some info' do
        before do
          expect(AgentConnectService).to receive(:user_info).with(code, nonce).and_return(user_info)
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
            expect(last_user.instructeur.agent_connect_id).to eq('sub')
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

            expect(instructeur.agent_connect_id).to eq('sub')
            expect(response).to redirect_to(instructeur_procedures_path)
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

            expect(instructeur.agent_connect_id).to eq('sub')
            expect(response).to redirect_to(instructeur_procedures_path)
          end
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

  def state_cookie
    cookies.encrypted[controller.class::STATE_COOKIE_NAME]
  end

  def nonce_cookie
    cookies.encrypted[controller.class::NONCE_COOKIE_NAME]
  end
end
