# frozen_string_literal: true

describe APIEntreprise::ExercicesAdapter do
  let(:siret) { '41816609600051' }
  let(:procedure) { create(:procedure) }
  subject { described_class.new(siret, procedure.id).to_params }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/dgfip\/etablissements\/#{siret}\/chiffres_affaires/)
      .to_return(body: File.read('spec/fixtures/files/api_entreprise/exercices.json', status: 200))
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  it { is_expected.to be_an_instance_of(Hash) }

  it 'contains several exercices attributes' do
    expect(subject[:exercices_attributes].size).to eq(2)
  end

  it 'contains informations in each exercices_attributes' do
    expect(subject[:exercices_attributes][0][:ca]).to eq('900001')
    expect(subject[:exercices_attributes][0][:date_fin_exercice].year).to eq(2015)
  end
end
