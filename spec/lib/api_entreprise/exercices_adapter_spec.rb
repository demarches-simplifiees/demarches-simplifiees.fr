require 'spec_helper'

describe ApiEntreprise::ExercicesAdapter do
  let(:siret) { '41816609600051' }
  let(:procedure_id) { 11 }
  subject { described_class.new(siret, procedure_id).to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/.*token=/)
      .to_return(body: File.read('spec/fixtures/files/api_entreprise/exercices.json', status: 200))
  end

  it { is_expected.to be_an_instance_of(Hash) }

  it 'contains several exercices attributes' do
    expect(subject[:exercices_attributes].size).to eq(3)
  end

  it 'contains informations in each exercices_attributes' do
    expect(subject[:exercices_attributes][0][:ca]).to eq('21009417')
    expect(subject[:exercices_attributes][0][:date_fin_exercice]).to eq("2013-12-31T00:00:00+01:00")
    expect(subject[:exercices_attributes][0][:date_fin_exercice_timestamp]).to eq(1388444400)
  end
end
