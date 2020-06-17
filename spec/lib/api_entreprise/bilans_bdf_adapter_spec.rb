describe ApiEntreprise::BilansBdfAdapter do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:adapter) { described_class.new(siret, procedure_id) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/bilans_entreprises_bdf\/#{siren}\?.*token=/)
      .to_return(body: body, status: status)
    allow_any_instance_of(ApiEntrepriseToken).to receive(:roles).and_return(["bilans_entreprise_bdf"])
    allow_any_instance_of(ApiEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context "when the SIREN is valid" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf.json') }
    let(:status) { 200 }

    it '#to_params class est une Hash ?' do
      expect(subject).to be_an_instance_of(Hash)
    end

    it "returns bilans bdf" do
      expect(subject[:entreprise_bilans_bdf][0][:valeur_ajoutee_bdf]).to eq("7848792")
    end
  end
end
