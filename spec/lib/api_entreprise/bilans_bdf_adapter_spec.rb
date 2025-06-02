# frozen_string_literal: true

describe APIEntreprise::BilansBdfAdapter do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:adapter) { described_class.new(siret, procedure_id) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/banque_de_france\/unites_legales\/#{siren}\/bilans/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return(["bilans_entreprise_bdf"])
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context "when the SIREN is valid" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf.json') }
    let(:status) { 200 }

    it '#to_params class est une Hash ?' do
      expect(subject).to be_an_instance_of(Hash)
    end

    it "returns bilans bdf" do
      expect(subject[:entreprise_bilans_bdf][0][:data][:valeurs_calculees][0][:excedent_brut_exploitation][:valeur]).to eq "9001"
    end
  end
end
