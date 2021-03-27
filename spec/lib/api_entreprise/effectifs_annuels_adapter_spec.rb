describe APIEntreprise::EffectifsAnnuelsAdapter do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:adapter) { described_class.new(siret, procedure_id) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/effectifs_annuels_acoss_covid\/#{siren}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context "when the SIREN is valid" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/effectifs_annuels.json') }
    let(:status) { 200 }

    it '#to_params class est une Hash ?' do
      expect(subject).to be_an_instance_of(Hash)
    end

    it "renvoie les effectifs de l'année antérieure" do
      expect(subject[:entreprise_effectif_annuel]).to eq(100.5)
    end
  end
end
