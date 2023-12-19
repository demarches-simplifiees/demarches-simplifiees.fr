describe RecoveriesController, type: :controller do
  describe 'GET #nature' do
    subject { get :nature }

    it { is_expected.to have_http_status(:success) }
  end

  describe 'POST #post_nature' do
    subject { post :post_nature, params: { nature: nature } }

    context 'when nature is collectivite' do
      let(:nature) { 'collectivite' }

      it { is_expected.to redirect_to(identification_recovery_path) }
    end

    context 'when nature is not collectivite' do
      let(:nature) { 'other' }

      it { is_expected.to redirect_to(support_recovery_path(error: :other_nature)) }
    end
  end

  describe 'Get #support' do
    subject { get :support }

    it { is_expected.to have_http_status(:success) }
  end
end
