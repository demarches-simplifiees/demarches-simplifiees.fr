# frozen_string_literal: true

describe APIEntreprise::PrivilegesAdapter do
  let(:body) { File.read('spec/fixtures/files/api_entreprise/privileges.json') }
  let(:status) { 200 }
  let(:token) { APIEntrepriseToken.new("secret-token") }
  let(:adapter) { described_class.new(token) }

  subject { adapter }

  before do
    stub_request(:get, "https://entreprise.api.gouv.fr/privileges")
      .to_return(body:, status:)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  it { is_expected.to be_valid }

  context 'when token is not valid or missing' do
    let(:token) { nil }
    let(:status) { 403 }
    let(:body) { '' }

    it { is_expected.not_to be_valid }
  end
end
