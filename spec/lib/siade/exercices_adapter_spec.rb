require 'spec_helper'

describe SIADE::ExercicesAdapter do
  let(:siret) { '41816609600051' }
  subject { described_class.new(siret).to_params }

  before do
    stub_request(:get, /https:\/\/api-dev.apientreprise.fr\/api\/v1\/etablissements\/exercices\/.*token=/)
        .to_return(body: File.read('spec/support/files/exercices.json', status: 200))
  end

  it '#to_params class est une Hash ?' do
    expect(subject).to be_an_instance_of(Array)
  end

  it 'have 3 exercices' do
    expect(subject.size).to eq(3)
  end

  context 'Attributs Exercices' do
    it 'L\'exercice contient bien un ca' do
      expect(subject[0][:ca]).to eq('21009417')
    end

    it 'L\'exercice contient bien une date de fin d\'exercice' do
      expect(subject[0][:dateFinExercice]).to eq("2013-12-31T00:00:00+01:00")
    end

    it 'L\'exercice contient bien une date_fin_exercice_timestamp' do
      expect(subject[0][:date_fin_exercice_timestamp]).to eq(1388444400)
    end
  end
end