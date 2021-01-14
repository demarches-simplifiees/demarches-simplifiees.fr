describe ApiEducation::AnnuaireEducationAdapter do
  let(:search_term) { '0050009H' }
  let(:adapter) { described_class.new(search_term) }
  subject { adapter.to_params }

  before do
    stub_request(:get, /https:\/\/data.education.gouv.fr\/api\/records\/1.0/)
      .to_return(body: body, status: status)
  end

  context "when responds with valid schema" do
    let(:body) { File.read('spec/fixtures/files/api_education/annuaire_education.json') }
    let(:status) { 200 }

    it '#to_params return vaid hash' do
      expect(subject).to be_an_instance_of(Hash)
      expect(subject['identifiant_de_l_etablissement']).to eq(search_term)
    end
  end

  context "when responds with invalid schema" do
    let(:body) { File.read('spec/fixtures/files/api_education/annuaire_education_invalid.json') }
    let(:status) { 200 }

    it '#to_params raise exception' do
      expect { subject }.to raise_exception(ApiEducation::AnnuaireEducationAdapter::InvalidSchemaError)
    end
  end
end
