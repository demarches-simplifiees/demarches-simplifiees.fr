# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillCommuneTypeDeChamp do
  let(:type_de_champ) { build(:type_de_champ_communes) }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  describe 'ancestors' do
    subject { described_class.new(type_de_champ) }

    it { is_expected.to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
  end

  describe '#transform_value_to_assignable_attributes' do
    subject(:transform_value_to_assignable_attributes) do
      described_class.build(type_de_champ).transform_value_to_assignable_attributes(value)
    end

    before do
      VCR.insert_cassette('api_geo_departements')
      VCR.insert_cassette('api_geo_communes')
    end

    after do
      VCR.eject_cassette('api_geo_departements')
      VCR.eject_cassette('api_geo_communes')
    end

    shared_examples "a transformation to" do |expected|
      it { is_expected.to match(expected) }
    end

    context 'when the value is nil' do
      let(:value) { nil }
      it_behaves_like "a transformation to", nil
    end

    context 'when the value is empty' do
      let(:value) { '' }
      it_behaves_like "a transformation to", nil
    end

    context 'when the value is a string' do
      let(:value) { 'hello' }
      it_behaves_like "a transformation to", nil
    end

    context 'when the value is an array of one element' do
      context 'when the first element is a valid departement code' do
        let(:value) { ['01'] }
        it_behaves_like "a transformation to", { code_departement: '01', departement: 'Ain' }
      end

      context 'when the first element is not a valid departement code' do
        let(:value) { ['totoro'] }
        it_behaves_like "a transformation to", nil
      end
    end

    context 'when the value is an array of two elements' do
      context 'when the first element is a valid departement code' do
        context 'when the second element is a valid insee code' do
          let(:value) { ['01', '01457'] }
          it_behaves_like "a transformation to", { code_departement: '01', departement: 'Ain', external_id: '01457', value: 'Vonnas (01540)' }
        end

        context 'when the second element is not a valid insee code' do
          let(:value) { ['01', 'totoro'] }
          it_behaves_like "a transformation to", nil
        end
      end

      context 'when the first element is not a valid departement code' do
        let(:value) { ['totoro', '01457'] }
        it_behaves_like "a transformation to", nil
      end
    end

    context 'when the value is an array of three or more elements' do
      context 'when the first element is a valid departement code' do
        context 'when the second element is a valid insee code' do
          let(:value) { ['01', '01457', 'hello'] }
          it_behaves_like "a transformation to", { code_departement: '01', departement: 'Ain', external_id: '01457', value: 'Vonnas (01540)' }
        end

        context 'when the second element is not a valid insee code' do
          let(:value) { ['01', 'totoro', 'hello'] }
          it_behaves_like "a transformation to", nil
        end
      end

      context 'when the first element is not a valid departement code' do
        let(:value) { ['totoro', '01457', 'hello'] }
        it_behaves_like "a transformation to", nil
      end
    end
  end
end
