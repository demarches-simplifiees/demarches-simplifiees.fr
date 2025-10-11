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
    let(:user_info) do
      {
        'sub' => 'sub',
        'email' => email,
        'given_name' => 'given',
        'usual_name' => 'usual'
      }
    end
    let(:amr) { [] }
    subject { get :callback, params: { code: code, state: state } }

    before do
      cookies.encrypted[controller.class::STATE_COOKIE_NAME] = original_state
      cookies.encrypted[controller.class::NONCE_COOKIE_NAME] = nonce
    end

    context 'when the callback code is correct' do
      let(:code) { 'correct' }
      let(:state) { original_state }

      context 'and user_info returns some info' do
        before do
          expect(ProConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token, amr])
        end

        context 'and the user does not have an account yet' do
          let(:initial_instructeur_count) { Instructeur.count }

          before do
            expect(controller).to receive(:sign_in)
          end

          it 'creates the user but not an instructeur' do
            expect { subject }.to change { User.count }.by(1).and change { Instructeur.count }.by(0)

            last_user = User.last

            expect(last_user.email).to eq(email)
            expect(last_user.confirmed_at).to be_present
            expect(last_user.email_verified_at).to be_present
            expect(response).to redirect_to(root_path)
            expect(state_cookie).to be_nil
            expect(nonce_cookie).to be_nil
            expect(Instructeur.count).to eq(initial_instructeur_count)
          end

          context 'when invites are pending' do
            let!(:invite) { create(:invite, email:, user: nil) }

            it 'links invites to the new user' do
              expect { subject }.to change { invite.reload.user }.from(nil)
              expect(invite.reload.user.email).to eq(email)
            end
          end
        end

        context 'and the user already has an account but is not an instructeur' do
          let!(:user) { create(:user, email: email) }
          let(:initial_instructeur_count) { Instructeur.count }

          before do
            expect(controller).to receive(:sign_in)
          end

          it 'does not create an instructeur' do
            expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)
            expect(response).to redirect_to(root_path)
            expect(Instructeur.count).to eq(initial_instructeur_count)
          end
        end

        context 'and the user already has an account as an instructeur' do
          let!(:instructeur) { create(:instructeur, email: email) }
          let(:initial_instructeur_count) { Instructeur.count }

          before do
            expect(controller).to receive(:sign_in)
          end

          it 'updates the instructeur pro_connect information' do
            expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)
            instructeur.reload

            expect(instructeur.pro_connect_id_token).to eq('id_token')
            expect(instructeur.user.pro_connect_informations.first.sub).to eq('sub')
            expect(instructeur.user.pro_connect_informations.first.given_name).to eq('given')
            expect(instructeur.user.pro_connect_informations.first.usual_name).to eq('usual')
            expect(response).to redirect_to(root_path)
            expect(Instructeur.count).to eq(initial_instructeur_count)
          end

          it "sets email_verified_at" do
            expect { subject }.to change { instructeur.user.reload.email_verified_at }.from(nil)
          end

          it "sets the pro_connect_session_info cookie" do
            subject

            expect(cookies.encrypted[ProConnectSessionConcern::SESSION_INFO_COOKIE_NAME]).to eq({ user_id: instructeur.user.id }.to_json)
          end
        end
      end

      context 'when connecting multiple times' do
        context 'with the same domain' do
          let!(:user) { create(:user, email: email) }
          let(:code) { 'correct' }
          let(:state) { original_state }
          let(:initial_instructeur_count) { Instructeur.count }

          before do
            expect(ProConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token, amr]).twice
            expect(controller).to receive(:sign_in).twice
          end

          it 'does not create an instructeur' do
            get :callback, params: { code: code, state: state }
            get :callback, params: { code: code, state: state }

            expect(Instructeur.count).to eq(initial_instructeur_count)
          end
        end

        context 'with different domains' do
          let!(:user) { create(:user, email: email) }
          let(:code) { 'correct' }
          let(:state) { original_state }
          let(:initial_instructeur_count) { Instructeur.count }

          before do
            expect(controller).to receive(:sign_in).twice
          end

          it 'does not create an instructeur' do
            expect(ProConnectService).to receive(:user_info).with(code, nonce).and_return([user_info, id_token, amr])
            get :callback, params: { code: code, state: state }

            expect(ProConnectService).to receive(:user_info).with(code, nonce).and_return([user_info.merge('sub' => 'sub2'), id_token, amr])
            get :callback, params: { code: code, state: state }

            expect(Instructeur.count).to eq(initial_instructeur_count)
          end
        end
      end

      context 'but user_info raises an error' do
        let(:initial_instructeur_count) { Instructeur.count }

        before do
          expect(ProConnectService).to receive(:user_info).and_raise(Rack::OAuth2::Client::Error.new(500, error: 'Unknown'))
        end

        it 'aborts the process' do
          expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)
          expect(response).to redirect_to(new_user_session_path)
          expect(Instructeur.count).to eq(initial_instructeur_count)
        end
      end
    end

    context 'when the callback state is not the original' do
      let(:code) { 'correct' }
      let(:state) { 'another state' }
      let(:initial_instructeur_count) { Instructeur.count }

      before { subject }

      it 'aborts the process' do
        expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)
        expect(response).to redirect_to(new_user_session_path)
        expect(Instructeur.count).to eq(initial_instructeur_count)
      end
    end

    context 'when the callback code is blank' do
      let(:code) { '' }
      let(:state) { original_state }
      let(:initial_instructeur_count) { Instructeur.count }

      it 'aborts the process' do
        expect { subject }.to change { User.count }.by(0).and change { Instructeur.count }.by(0)
        expect(response).to redirect_to(new_user_session_path)
        expect(Instructeur.count).to eq(initial_instructeur_count)
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
