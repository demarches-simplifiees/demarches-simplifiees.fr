# frozen_string_literal: true

describe APIEntreprise::AttestationFiscaleAdapter do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:user_id) { 1 }
  let(:adapter) { described_class.new(siret, procedure.id, user_id) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/dgfip\/unites_legales\/#{siren}\/attestation_fiscale/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:can_fetch_attestation_fiscale?).and_return(true)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context "when the SIREN is valid" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/attestation_fiscale.json') }
    let(:status) { 200 }

    it '#to_params class est une Hash ?' do
      expect(subject).to be_an_instance_of(Hash)
    end

    it "returns url of attestation_fiscale" do
      expect(subject[:entreprise_attestation_fiscale_url]).to eq("https://storage.entreprise.api.gouv.fr/siade/1569139162-b99824d9c764aae19a862a0af-attestation_fiscale_dgfip.pdf")
    end
  end
end
