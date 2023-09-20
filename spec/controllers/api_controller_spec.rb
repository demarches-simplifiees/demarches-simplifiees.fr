describe APIController, type: :controller do
  describe 'authenticate_from_token' do
    let(:procedure) { create(:procedure) }
    let(:admin) { procedure.administrateurs.first }

    subject do
      controller.send(:authenticate_from_token)
      assigns(:api_token)
    end

    context 'when the admin has not any token' do
      context 'and the token is not given' do
        it { is_expected.to be nil }
      end
    end

    context 'when the admin has a token' do
      let(:token_bearer_couple) { APIToken.generate(admin) }
      let(:token) { token_bearer_couple[0] }
      let(:bearer) { token_bearer_couple[1] }

      context 'and the token is given by params' do
        before { controller.params[:token] = bearer }

        it { is_expected.to eq(token) }
      end

      context 'and the token is given by header' do
        before do
          valid_headers = { 'Authorization' => "Bearer token=#{bearer}" }
          request.headers.merge!(valid_headers)
        end

        it { is_expected.to eq(token) }
      end

      context 'and the token is not given' do
        it { is_expected.to be nil }
      end
    end
  end
end
