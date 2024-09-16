# frozen_string_literal: true

describe AgentConnectService do
  describe '.logout_url' do
    let(:id_token) { 'id_token' }

    before do
      ::AGENT_CONNECT ||= {}
      allow(AGENT_CONNECT).to receive(:[])
        .with(:end_session_endpoint).and_return("https://agent-connect.fr/logout")
    end

    subject { described_class.logout_url(id_token, host_with_port: 'test.host') }

    it 'returns the correct url' do
      expect(subject).to eq("https://agent-connect.fr/logout?id_token_hint=id_token&post_logout_redirect_uri=http%3A%2F%2Ftest.host%2Flogout")
    end
  end
end
