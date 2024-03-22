describe TargetedUserLinksController, type: :controller do
  describe '#show' do
    context 'avis' do
      let!(:targeted_user_link) { create(:targeted_user_link, target_context: target_context, target_model: target_model, user: user) }

      let(:target_context) { :avis }
      let!(:expert) { create(:expert, user: user) }
      let!(:target_model) { create(:avis, experts_procedure: expert_procedure) }
      let!(:expert_procedure) { create(:experts_procedure, expert: expert) }

      context 'not connected as active expert' do
        let(:user) { create(:user, last_sign_in_at: 2.days.ago) }

        before { get :show, params: { id: targeted_user_link.id } }

        it 'redirects to expert_avis_url' do
          expect(response).to redirect_to(expert_avis_path(target_model.procedure, target_model))
          expect(controller.stored_location_for(:user)).to eq(controller.request.path)
        end
      end

      context 'not connected as inactive expert' do
        let(:user) { create(:user, last_sign_in_at: nil) }

        before { get :show, params: { id: targeted_user_link.id } }

        it 'redirects to sign_up_expert_avis_url' do
          expect(response).to redirect_to(sign_up_expert_avis_path(target_model.procedure, target_model, email: user.email))
        end
      end

      context 'connected as expected user' do
        let(:user) { create(:user, last_sign_in_at: 2.days.ago) }

        before do
          sign_in(targeted_user_link.user)
          get :show, params: { id: targeted_user_link.id }
        end

        it 'redirects to expert_avis_url' do
          expect(response).to redirect_to(expert_avis_path(target_model.procedure, target_model))
        end
      end

      context 'connected as different user' do
        let(:user) { create(:user, last_sign_in_at: 2.days.ago) }

        before do
          sign_in(create(:expert).user)
          get :show, params: { id: targeted_user_link.id }
        end

        it 'renders error page ' do
          expect(response).to have_http_status(200)
        end
      end
    end

    context 'with invite having user' do
      let!(:targeted_user_link) { create(:targeted_user_link, target_context: target_context, target_model: target_model, user: user) }

      let(:target_context) { 'invite' }
      let(:target_model) { create(:invite, user: user) }

      context 'connected with expected user' do
        let(:user) { build(:user, last_sign_in_at: 2.days.ago) }
        before do
          sign_in(targeted_user_link.user)
          get :show, params: { id: targeted_user_link.id }
        end
        it 'works' do
          expect(response).to redirect_to(invite_path(target_model))
        end
      end

      context 'connected as different user' do
        let(:user) { create(:user, last_sign_in_at: 2.days.ago) }

        before do
          sign_in(create(:expert).user)
          get :show, params: { id: targeted_user_link.id }
        end

        it 'renders error page ' do
          expect(response).to have_http_status(200)
        end
      end

      context 'when invite user does not exists' do
        let(:user) { nil }
        before { get :show, params: { id: targeted_user_link.id } }
        it 'works' do
          expect(response).to redirect_to(invite_path(target_model, email: target_model.email))
        end
      end

      context 'when there is no dossier visible anymore' do
        let(:user) { nil }
        let(:target_model) { create(:invite, user: user, dossier: create(:dossier, hidden_by_user_at: 1.day.ago)) }

        it 'redirect nicely' do
          get :show, params: { id: targeted_user_link.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to match(/dossier n’est plus accessible/)
        end

        it 'redirect nicely also when user is signed on another account' do
          sign_in(create(:expert).user)
          get :show, params: { id: targeted_user_link.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to match(/dossier n’est plus accessible/)
        end
      end
    end

    context 'with invite not having user' do
      let!(:targeted_user_link) { create(:targeted_user_link, target_context: target_context, target_model: target_model, user: user) }
      let(:target_context) { 'invite' }
      let(:user_email) { 'not_yet_registered@a.com' }
      let(:target_model) { create(:invite, user: nil, email: user_email) }

      context 'connected with expected user' do
        let(:user) { create(:user, email: user_email, last_sign_in_at: 2.days.ago) }
        before do
          sign_in(user)
          get :show, params: { id: targeted_user_link.id }
        end
        it 'works' do
          expect(response).to redirect_to(invite_path(target_model))
        end
      end

      context 'connected as different user' do
        let(:user) { create(:user, last_sign_in_at: 2.days.ago) }

        before do
          sign_in(create(:expert).user)
          get :show, params: { id: targeted_user_link.id }
        end

        it 'renders error page ' do
          expect(response).to have_http_status(200)
        end
      end

      context 'when invite user does not exists' do
        let(:user) { nil }
        before { get :show, params: { id: targeted_user_link.id } }
        it 'works' do
          expect(response).to redirect_to(invite_path(target_model, email: target_model.email))
        end
      end
    end

    context 'not found' do
      it 'redirect nicely' do
        sign_in(create(:user))
        get :show, params: { id: "asldjiasld" }
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to be_present
        expect(flash[:error]).to match(/invitation n’est plus valable/)
      end
    end
  end
end
