describe API::V2::BaseController, type: :controller do
  describe 'ensure_authorized_network and token_is_not_expired' do
    let(:admin) { create(:administrateur) }
    let(:token_bearer_couple) { APIToken.generate(admin) }
    let(:token) { token_bearer_couple[0] }
    let(:bearer) { token_bearer_couple[1] }
    let(:remote_ip) { '0.0.0.0' }

    controller(API::V2::BaseController) { def fake_action = render(plain: 'Hello, World!') }

    before do
      routes.draw { get 'fake_action' => 'api/v2/base#fake_action' }
      valid_headers = { 'Authorization' => "Bearer token=#{bearer}" }
      request.headers.merge!(valid_headers)
      request.remote_ip = remote_ip
    end

    describe 'GET #index' do
      subject { get :fake_action }

      context 'when no authorized networks are defined and the token is not expired' do
        it { is_expected.to have_http_status(:ok) }
      end

      context 'when the token is expired' do
        before do
          token.update!(expires_at: 1.day.ago)
        end

        it { is_expected.to have_http_status(:unauthorized) }
      end

      context 'when this is precisely the day the token expires' do
        before do
          token.update!(expires_at: Time.zone.today)
        end

        it { is_expected.to have_http_status(:ok) }
      end

      context 'when a single authorized network is defined' do
        before do
          token.update!(authorized_networks: [IPAddr.new('192.168.1.0/24')])
        end

        context 'and the request comes from it' do
          let(:remote_ip) { '192.168.1.23' }

          it { is_expected.to have_http_status(:ok) }
        end

        context 'and the request does not come from it' do
          let(:remote_ip) { '192.168.2.2' }

          it { is_expected.to have_http_status(:forbidden) }
        end
      end
    end
  end
end
