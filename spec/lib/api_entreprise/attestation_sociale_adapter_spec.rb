describe APIEntreprise::AttestationSocialeAdapter do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:adapter) { described_class.new(siret, procedure.id) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/attestations_sociales_acoss\/#{siren}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return(["attestations_sociales"])
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context "when the SIREN is valid" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/attestation_sociale.json') }
    let(:status) { 200 }

    it '#to_params class est une Hash ?' do
      expect(subject).to be_an_instance_of(Hash)
    end

    it "renvoie l'url de l'attestation sociale" do
      expect(subject[:entreprise_attestation_sociale_url]).to eq("https://storage.entreprise.api.gouv.fr/siade/1569156881-f749d75e2bfd443316e2e02d59015f-attestation_vigilance_acoss.pdf")
    end
  end
end
