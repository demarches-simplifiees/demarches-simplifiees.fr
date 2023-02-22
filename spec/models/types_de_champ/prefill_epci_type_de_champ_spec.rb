# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillEpciTypeDeChamp do
  let(:procedure) { create(:procedure) }
  let(:type_de_champ) { build(:type_de_champ_epci, procedure: procedure) }
  let(:champ) { create(:champ_epci, type_de_champ: type_de_champ) }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe 'ancestors' do
    subject { described_class.new(type_de_champ, procedure.active_revision) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#possible_values' do
    let(:expected_values) do
      departements.map { |departement| "#{departement[:code]} (#{departement[:name]}) : https://geo.api.gouv.fr/epcis?codeDepartement=#{departement[:code]}" }
    end
    subject(:possible_values) { described_class.new(type_de_champ, procedure.active_revision).possible_values }

    before do
      VCR.insert_cassette('api_geo_departements')
      VCR.insert_cassette('api_geo_epcis')
    end

    after do
      VCR.eject_cassette('api_geo_departements')
      VCR.eject_cassette('api_geo_epcis')
    end

    it { expect(possible_values).to match(expected_values) }
  end

  describe '#example_value' do
    let(:departement_code) { departements.pick(:code) }
    let(:epci_code) { APIGeoService.epcis(departement_code).pick(:code) }
    subject(:example_value) { described_class.new(type_de_champ, procedure.active_revision).example_value }

    before do
      VCR.insert_cassette('api_geo_departements')
      VCR.insert_cassette('api_geo_epcis')
    end

    after do
      VCR.eject_cassette('api_geo_departements')
      VCR.eject_cassette('api_geo_epcis')
    end

    it { is_expected.to eq([departement_code, epci_code]) }
  end

  describe '#to_assignable_attributes' do
    subject(:to_assignable_attributes) { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

    shared_examples "a transformation to" do |code_departement, value|
      it { is_expected.to match({ code_departement: code_departement, value: value, id: champ.id }) }
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it_behaves_like "a transformation to", nil, nil
    end

    context 'when the value is empty' do
      let(:value) { '' }

      it_behaves_like "a transformation to", nil, nil
    end

    context 'when the value is a string' do
      let(:value) { 'hello' }

      it_behaves_like "a transformation to", nil, nil
    end

    context 'when the value is an array of one element' do
      let(:value) { ['01'] }

      it_behaves_like "a transformation to", '01', nil
    end

    context 'when the value is an array of two elements' do
      let(:value) { ['01', '200042935'] }

      it_behaves_like "a transformation to", '01', '200042935'
    end

    context 'when the value is an array of three or more elements' do
      let(:value) { ['01', '200042935', 'hello'] }

      it_behaves_like "a transformation to", '01', '200042935'
    end
  end

  private

  def departements
    APIGeoService.departements.sort_by { |departement| departement[:code] }
  end
end
