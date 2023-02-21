RSpec.describe PrefillDescription, type: :model do
  include Rails.application.routes.url_helpers

  describe '#update' do
    let(:prefill_description) { described_class.new(build(:procedure)) }
    let(:selected_type_de_champ_ids) { ['1', '2'] }
    subject(:update) { prefill_description.update({ selected_type_de_champ_ids: selected_type_de_champ_ids.join(' ') }) }

    context 'when selected_type_de_champ_ids are given' do
      it 'populate selected_type_de_champ_ids' do
        expect { update }.to change { prefill_description.selected_type_de_champ_ids }.from([]).to(selected_type_de_champ_ids)
      end
    end
  end

  describe '#types_de_champ' do
    let(:procedure) { create(:procedure) }
    let!(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }
    let(:prefill_description) { described_class.new(procedure) }

    subject(:types_de_champ) { prefill_description.types_de_champ }

    it { expect(types_de_champ.count).to eq(1) }

    it { expect(types_de_champ.first).to eql(TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ, procedure.active_revision)) }

    shared_examples "filters out non fillable types de champ" do |type_de_champ_name|
      context "when the procedure has a #{type_de_champ_name} champ" do
        let(:non_fillable_type_de_champ) { create(type_de_champ_name, procedure: procedure) }

        it { expect(prefill_description.types_de_champ).not_to include(non_fillable_type_de_champ) }
      end
    end

    it_behaves_like "filters out non fillable types de champ", :type_de_champ_header_section
    it_behaves_like "filters out non fillable types de champ", :type_de_champ_explication

    context 'when the procedure contains prefillable and non prefillable types de champ' do
      let!(:non_prefillable_type_de_champ) { create(:type_de_champ_carte, procedure: procedure) }
      let!(:prefillable_type_de_champ) { create(:type_de_champ_decimal_number, procedure: procedure) }

      it "sort types de champ by putting prefillable ones first" do
        expect(prefill_description.types_de_champ).to eq([
          type_de_champ,
          prefillable_type_de_champ,
          non_prefillable_type_de_champ
        ])
      end
    end
  end

  describe '#include?' do
    let(:prefill_description) { described_class.new(build(:procedure)) }
    let(:type_de_champ_id) { 1 }
    subject(:included) { prefill_description.include?(type_de_champ_id) }

    context 'when the id has been added to the prefill_description' do
      before { prefill_description.update(selected_type_de_champ_ids: '1') }

      it { expect(included).to eq(true) }
    end

    context 'when the id has not be added to the prefill_description' do
      it { expect(included).to eq(false) }
    end
  end

  describe '#link_too_long?' do
    let(:procedure) { create(:procedure) }
    let(:prefill_description) { described_class.new(procedure) }

    subject(:too_long) { prefill_description.link_too_long? }

    before { prefill_description.update(selected_type_de_champ_ids: create_list(:type_de_champ_text, type_de_champs_count, procedure: procedure).map(&:id)).join(' ') }

    context 'when the prefill link is too long' do
      let(:type_de_champs_count) { 65 }

      it { expect(too_long).to eq(true) }
    end

    context 'when the prefill link is not too long' do
      let(:type_de_champs_count) { 2 }

      it { expect(too_long).to eq(false) }
    end
  end

  describe '#prefill_link', vcr: { cassette_name: 'api_geo_regions' } do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ_text) { build(:type_de_champ_text, procedure: procedure) }
    let(:type_de_champ_epci) { build(:type_de_champ_epci, procedure: procedure) }
    let(:type_de_champ_repetition) { create(:type_de_champ_repetition, :with_types_de_champ, :with_region_types_de_champ, procedure: procedure) }
    let(:prefillable_subchamps) { TypesDeChamp::PrefillRepetitionTypeDeChamp.new(type_de_champ_repetition, procedure.active_revision).send(:prefillable_subchamps) }
    let(:region_repetition) { prefillable_subchamps.third }
    let(:prefill_description) { described_class.new(procedure) }

    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear

      VCR.insert_cassette('api_geo_departements')
      VCR.insert_cassette('api_geo_epcis')

      prefill_description.update(selected_type_de_champ_ids: [type_de_champ_text.id, type_de_champ_epci.id, type_de_champ_repetition.id])
    end

    after do
      VCR.eject_cassette('api_geo_departements')
      VCR.eject_cassette('api_geo_epcis')
    end

    it "builds the URL to create a new prefilled dossier" do
      expect(prefill_description.prefill_link).to eq(
        commencer_url(
          path: procedure.path,
          "champ_#{type_de_champ_text.to_typed_id}" => TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_text, procedure.active_revision).example_value,
          "champ_#{type_de_champ_epci.to_typed_id}" => TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_epci, procedure.active_revision).example_value,
          "champ_#{type_de_champ_repetition.to_typed_id}" => TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_repetition, procedure.active_revision).example_value
        )
      )
    end
  end

  describe '#prefill_query', vcr: { cassette_name: 'api_geo_regions' } do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ_text) { create(:type_de_champ_text, procedure: procedure) }
    let(:type_de_champ_epci) { TypesDeChamp::PrefillTypeDeChamp.build(create(:type_de_champ_epci, procedure: procedure), procedure.active_revision) }
    let(:type_de_champ_repetition) { build(:type_de_champ_repetition, :with_types_de_champ, :with_region_types_de_champ, procedure: procedure) }
    let(:prefillable_subchamps) { TypesDeChamp::PrefillRepetitionTypeDeChamp.new(type_de_champ_repetition, procedure.active_revision).send(:prefillable_subchamps) }
    let(:region_repetition) { prefillable_subchamps.third }
    let(:prefill_description) { described_class.new(procedure) }
    let(:expected_query) do
      <<~TEXT
        curl --request POST '#{api_public_v1_dossiers_url(procedure)}' \\
             --header 'Content-Type: application/json' \\
             --data '{"champ_#{type_de_champ_text.to_typed_id}": "#{TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_text, procedure.active_revision).example_value}", "champ_#{type_de_champ_epci.to_typed_id}": #{TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_epci, procedure.active_revision).example_value}, "champ_#{type_de_champ_repetition.to_typed_id}": #{TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_repetition, procedure.active_revision).example_value}}'
      TEXT
    end

    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear

      VCR.insert_cassette('api_geo_departements')
      VCR.insert_cassette('api_geo_epcis')

      prefill_description.update(selected_type_de_champ_ids: [type_de_champ_text.id, type_de_champ_epci.id, type_de_champ_repetition.id])
    end

    after do
      VCR.eject_cassette('api_geo_departements')
      VCR.eject_cassette('api_geo_epcis')
    end

    it "builds the query to create a new prefilled dossier" do
      expect(prefill_description.prefill_query).to eq(expected_query)
    end
  end
end
