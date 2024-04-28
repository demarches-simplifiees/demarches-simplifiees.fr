# frozen_string_literal: true

describe APIEducation::AnnuaireEducationAdapter do
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

    it '#to_params return valid hash' do
      expect(subject).to be_an_instance_of(Hash)
      expect(subject['identifiant_de_l_etablissement']).to eq(search_term)
      expect(subject['code_type_contrat_prive']).to eq(99)
    end
  end

  context "when responds with code_type_contrat_prive as string" do
    let(:body) { File.read('spec/fixtures/files/api_education/annuaire_education_bug.json') }
    let(:status) { 200 }

    it '#to_params return valid hash' do
      expect(subject).to be_an_instance_of(Hash)
      expect(subject['identifiant_de_l_etablissement']).to eq(search_term)
      expect(subject['code_type_contrat_prive']).to eq(99)
    end
  end

  context "when responds with invalid schema" do
    let(:body) { File.read('spec/fixtures/files/api_education/annuaire_education_invalid.json') }
    let(:status) { 200 }

    it '#to_params raise exception' do
      expect { subject }.to raise_exception(APIEducation::AnnuaireEducationAdapter::InvalidSchemaError)
    end
  end

  context "when responds with empty schema" do
    let(:body) { File.read('spec/fixtures/files/api_education/annuaire_education_empty.json') }
    let(:status) { 200 }

    it '#to_params returns nil' do
      expect(subject).to eq(nil)
    end
  end
end
