describe RecoveriesController, type: :controller do
  include Dry::Monads[:result]

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

  describe 'ensure_agent_connect_is_used' do
    subject { post :selection }

    before do
      allow(controller).to receive(:ensure_collectivite_territoriale).and_return(true)
      allow(controller).to receive(:selection).and_return(true)
    end

    context 'when agent connect is used' do
      let(:instructeur) { create(:instructeur, :with_agent_connect_information) }

      before do
        allow(controller).to receive(:current_instructeur).and_return(instructeur)
      end

      it { is_expected.to have_http_status(:success) }
    end

    context 'when agent connect is not used' do
      it { is_expected.to redirect_to(support_recovery_path(error: :must_use_agent_connect)) }
    end
  end

  describe 'ensure_collectivite_territoriale' do
    subject { post :selection }

    before do
      allow(controller).to receive(:ensure_agent_connect_is_used).and_return(true)
      allow(controller).to receive(:siret).and_return('123')
      allow(controller).to receive(:selection).and_return(true)
    end

    context 'when collectivite territoriale' do
      before do
        allow(APIRechercheEntreprisesService).to receive(:collectivite_territoriale?).and_return(true)
      end

      it { is_expected.to have_http_status(:success) }
    end

    context 'when not collectivite territoriale' do
      before do
        allow(APIRechercheEntreprisesService).to receive(:collectivite_territoriale?).and_return(false)
      end

      it { is_expected.to redirect_to(support_recovery_path(error: 'not_collectivite_territoriale')) }
    end
  end

  context 'when the current instructeur used agent connect and works for a collectivite territoriale' do
    let(:instructeur) { create(:instructeur, :with_agent_connect_information) }
    let(:api_recherche_result) do
      { nom_complet: 'name', complements: { collectivite_territoriale: { is: :present } } }
    end

    before do
      allow(controller).to receive(:current_instructeur).and_return(instructeur)
      allow_any_instance_of(APIRechercheEntreprisesService).to receive(:call)
        .and_return(Success(api_recherche_result))
    end

    describe 'GET #identification' do
      subject { get :identification }

      it { is_expected.to have_http_status(:success) }
    end

    describe 'POST #post_identification' do
      subject { post :post_identification, params: { previous_email: 'email@a.com' } }

      it do
        is_expected.to redirect_to(selection_recovery_path)
        expect(cookies[:recover_previous_email]).to eq('email@a.com')
      end
    end
  end
end
