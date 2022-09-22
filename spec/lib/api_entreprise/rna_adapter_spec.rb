describe APIEntreprise::RNAAdapter do
  let(:siret) { '50480511000013' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:adapter) { described_class.new(siret, procedure_id) }

  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\//)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  context 'when siret is not valid' do
    let(:siret) { '234567' }
    let(:body) { '' }
    let(:status) { 404 }

    it { is_expected.to eq({}) }
  end

  context "when responds with valid schema" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }
    let(:status) { 200 }

    it '#to_params return vaid hash' do
      expect(subject).to be_an_instance_of(Hash)
      expect(subject["association_rna"]).to eq('W595001988')
      expect(subject["association_titre"]).to eq('UN SUR QUATRE')
      expect(subject["association_objet"]).to eq("valoriser, transmettre et partager auprès des publics les plus larges possibles, les bienfaits de l'immigration, la richesse de la diversité et la curiosité de l'autre autrement")
      expect(subject["association_date_creation"]).to eq('2014-01-23')
      expect(subject["association_date_declaration"]).to eq('2014-01-24')
      expect(subject["association_date_publication"]).to eq('2014-02-08')
    end
  end

  context "when responds with invalid schema" do
    let(:body) { File.read('spec/fixtures/files/api_entreprise/associations_invalid.json') }
    let(:status) { 200 }

    it '#to_params raise exception' do
      expect { subject }.to raise_exception(APIEntreprise::RNAAdapter::InvalidSchemaError)
    end
  end
end
