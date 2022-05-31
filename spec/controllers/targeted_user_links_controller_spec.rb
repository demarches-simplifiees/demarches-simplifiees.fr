describe TargetedUserLinksController, type: :controller do
  describe '#show' do
    let!(:expert) { create(:expert, user: expert_user) }
    let!(:avis) { create(:avis, experts_procedure: expert_procedure) }
    let!(:expert_procedure) { create(:experts_procedure, expert: expert) }
    let!(:targeted_user_link) { create(:targeted_user_link, target_context: :avis, target_model: avis, user: expert_user) }

    context 'not connected as active expert' do
      let(:expert_user) { create(:user, last_sign_in_at: 2.days.ago) }

      before { get :show, params: { id: targeted_user_link.id } }

      it 'redirects to expert_avis_url' do
        expect(response).to redirect_to(expert_avis_path(avis.procedure, avis))
      end
    end

    context 'not connected as inactive expert' do
      let(:expert_user) { create(:user, last_sign_in_at: nil) }

      before { get :show, params: { id: targeted_user_link.id } }

      it 'redirects to sign_up_expert_avis_url' do
        expect(response).to redirect_to(sign_up_expert_avis_path(avis.procedure, avis, email: expert_user.email))
      end
    end

    context 'connected as expected user' do
      let(:expert_user) { create(:user, last_sign_in_at: 2.days.ago) }

      before do
        sign_in(targeted_user_link.user)
        get :show, params: { id: targeted_user_link.id }
      end

      it 'redirects to expert_avis_url' do
        expect(response).to redirect_to(expert_avis_path(avis.procedure, avis))
      end
    end

    context 'connected as different user' do
      let(:expert_user) { create(:user, last_sign_in_at: 2.days.ago) }

      before do
        sign_in(create(:expert).user)
        get :show, params: { id: targeted_user_link.id }
      end

      it 'renders error page ' do
        expect(response).to have_http_status(200)
      end
    end
  end
end
