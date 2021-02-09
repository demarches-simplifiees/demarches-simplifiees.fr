describe APIEntreprise::AttestationFiscaleAdapter do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:user_id) { 1 }
  let(:adapter) { described_class.new(siret, procedure.id, user_id) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/attestations_fiscales_dgfip\/#{siren}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return(["attestations_fiscales"])
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context "when the SIREN is valid" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/attestation_fiscale.json') }
    let(:status) { 200 }

    it '#to_params class est une Hash ?' do
      expect(subject).to be_an_instance_of(Hash)
    end

    it "returns url of attestation_fiscale" do
      expect(subject[:entreprise_attestation_fiscale_url]).to eq("https://storage.entreprise.api.gouv.fr/siade/1569156756-f6b7779f99fa95cd60dc03c04fcb-attestation_fiscale_dgfip.pdf")
    end
  end
end
