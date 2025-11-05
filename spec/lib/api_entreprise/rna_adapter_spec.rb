# frozen_string_literal: true

describe APIEntreprise::RNAAdapter do
  let(:rna) { 'W111111111' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:adapter) { described_class.new(rna, procedure_id) }

  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{rna}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context 'when rna is not valid' do
    let(:rna) { '234567' }
    let(:body) { '' }
    let(:status) { 404 }

    it { is_expected.to eq({}) }
  end

  context "when responds with valid schema" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }
    let(:status) { 200 }

    it '#to_params return valid hash' do
      expect(subject).to be_an_instance_of(Hash)
      expect(subject["association_rna"]).to eq("W751080001")
      expect(subject["association_titre"]).to eq("LA PRÉVENTION ROUTIERE")
      expect(subject["association_objet"]).to eq("L'association a pour objet de promouvoir la pratique du sport de haut niveau et de contribuer à la formation des jeunes sportifs.")
      expect(subject["association_date_declaration"]).to eq("2019-01-01")
      expect(subject["association_date_publication"]).to eq("2018-01-01")
      expect(subject["adresse"]).to eq({
        complement: "",
        numero_voie: "33",
        type_voie: "rue",
        libelle_voie: "de Modagor",
        distribution: "dummy",
        code_insee: "75108",
        code_postal: "75009",
        commune: "Paris",
      })
    end
  end
end
