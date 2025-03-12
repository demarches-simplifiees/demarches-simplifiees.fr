# frozen_string_literal: true

describe Pro_ConnectService
    before do
      ::PRO_CONNECT ||= {}
      allow(PRO_CONNECT).to receive(:[])
        .with(:end_session_endpoint).and_return("https://agent-connect.fr/logout")
    end

    subject { described_class.logout_url(id_token, host_with_port: 'test.host') }

    it 'returns the correct url' do
      expect(subject).to eq("https://agent-connect.fr/logout?id_token_hint=id_token&post_logout_redirect_uri=http%3A%2F%2Ftest.host%2Flogout")
    end
  end

  xdescribe '.email_domain_is_in_mandatory_list?' do
    subject { described_class.email_domain_is_in_mandatory_list?(email) }

    context 'when email domain is beta.gouv.fr' do
      let(:email) { 'user@beta.gouv.fr' }
      it { is_expected.to be true }
    end

    context 'when email domain is modernisation.gouv.fr' do
      let(:email) { 'user@modernisation.gouv.fr' }
      it { is_expected.to be true }
    end

    context 'when email domain is not in the mandatory list' do
      let(:email) { 'user@example.com' }
      it { is_expected.to be false }
    end

    context 'when email contains whitespace' do
      let(:email) { ' user@beta.gouv.fr ' }
      it { is_expected.to be true }
    end
  end
end
