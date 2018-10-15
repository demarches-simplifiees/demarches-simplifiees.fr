require 'spec_helper'

describe ApiEntreprise::ExercicesAdapter do
  let(:siret) { '41816609600051' }
  let(:procedure_id) { 11 }
  subject { described_class.new(siret, procedure_id).to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\/.*token=/)
      .to_return(body: File.read('spec/fixtures/files/api_entreprise/exercices.json', status: 200))
  end

  it '#to_params class est un Hash ?' do
    expect(subject).to be_an_instance_of(Hash)
  end

  it 'have 3 exercices' do
    expect(subject[:exercices_attributes].size).to eq(3)
  end

  context 'Attributs Exercices' do
    it 'L\'exercice contient bien un ca' do
      expect(subject[:exercices_attributes][0][:ca]).to eq('21009417')
    end

    it 'L\'exercice contient bien une date de fin d\'exercice' do
      expect(subject[:exercices_attributes][0][:date_fin_exercice]).to eq("2013-12-31T00:00:00+01:00")
    end

    it 'L\'exercice contient bien une date_fin_exercice_timestamp' do
      expect(subject[:exercices_attributes][0][:date_fin_exercice_timestamp]).to eq(1388444400)
    end
  end
end
