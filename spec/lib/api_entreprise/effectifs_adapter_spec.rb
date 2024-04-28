# frozen_string_literal: true

describe APIEntreprise::EffectifsAdapter do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:annee) { "2020" }
  let(:mois) { "02" }
  let(:adapter) { described_class.new(siret, procedure_id, annee, mois) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/gip_mds\/etablissements\/#{siret}\/effectifs_mensuels\/#{mois}\/annee\/#{annee}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context "when the SIREN is valid" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/effectifs.json') }
    let(:status) { 200 }

    it '#to_params class est une Hash ?' do
      expect(subject).to be_an_instance_of(Hash)
    end

    it "renvoie les effectifs du mois demandé" do
      expect(subject[:entreprise_effectif_mensuel]).to eq(12.34)
    end
  end
end
