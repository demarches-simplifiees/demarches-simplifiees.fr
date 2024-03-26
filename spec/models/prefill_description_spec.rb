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

    context "type_de_champ id" do
      let(:type_de_champ_id) { 1 }
      subject(:included) { prefill_description.include?(type_de_champ_id.to_s) }

      context 'when the id of a type_de_champ has been added to the prefill_description' do
        before { prefill_description.update(selected_type_de_champ_ids: '1') }

        it { expect(included).to eq(true) }
      end

      context 'when the id has not be added to the prefill_description' do
        it { expect(included).to eq(false) }
      end
    end

    context "identity information" do
      subject(:included) { prefill_description.include?('prenom') }

      context 'when the first_name has been added to the prefill_description' do
        before { prefill_description.update(identity_items_selected: 'prenom') }

        it { expect(included).to eq(true) }
      end

      context 'when the first_name has not been added to the prefill_description' do
        it { expect(included).to eq(false) }
      end
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

  describe '#prefill_link' do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ_text) { build(:type_de_champ_text, procedure: procedure) }
    let(:type_de_champ_epci) { build(:type_de_champ_epci, procedure: procedure) }
    let(:type_de_champ_repetition) { create(:type_de_champ_repetition, :with_types_de_champ, :with_region_types_de_champ, procedure: procedure) }
    let(:prefillable_subchamps) { TypesDeChamp::PrefillRepetitionTypeDeChamp.new(type_de_champ_repetition, procedure.active_revision).send(:prefillable_subchamps) }
    let(:region_repetition) { prefillable_subchamps.third }
    let(:prefill_description) { described_class.new(procedure) }

    before do
      prefill_description.update(selected_type_de_champ_ids: [type_de_champ_text.id, type_de_champ_epci.id, type_de_champ_repetition.id], identity_items_selected: "prenom")
    end

    it "builds the URL to create a new prefilled dossier" do
      expect(prefill_description.prefill_link).to eq(
        CGI.unescape(
          commencer_url(
            path: procedure.path,
            "champ_#{type_de_champ_text.to_typed_id_for_query}" => TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_text, procedure.active_revision).example_value,
            "champ_#{type_de_champ_epci.to_typed_id_for_query}" => TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_epci, procedure.active_revision).example_value,
            "champ_#{type_de_champ_repetition.to_typed_id_for_query}" => TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_repetition, procedure.active_revision).example_value,
            "identite_prenom" => I18n.t("views.prefill_descriptions.edit.examples.prenom")
          )
        )
      )
    end
  end

  describe '#prefill_query' do
    let(:procedure) do
      create(:procedure, types_de_champ_public: [
        { type: :text },
        { type: :epci },
        {
          type: :repetition, children: [
            { type: :text },
            { type: :integer_number },
            { type: :regions }
          ]
        }
      ])
    end
    let(:type_de_champ_text) { procedure.active_revision.types_de_champ_public.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:text) } }
    let(:type_de_champ_epci) { procedure.active_revision.types_de_champ_public.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:epci) } }
    let(:type_de_champ_repetition) { procedure.active_revision.types_de_champ_public.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:repetition) } }

    let(:prefill_type_de_champ_epci) { TypesDeChamp::PrefillTypeDeChamp.build(type_de_champ_epci, procedure.active_revision) }
    let(:prefillable_subchamps) { TypesDeChamp::PrefillRepetitionTypeDeChamp.new(type_de_champ_repetition, procedure.active_revision).send(:prefillable_subchamps) }

    let(:text_repetition) { prefillable_subchamps.first }
    let(:integer_repetition) { prefillable_subchamps.second }
    let(:region_repetition) { prefillable_subchamps.third }

    let(:prefill_description) { described_class.new(procedure) }
    let(:expected_query) do
      <<~TEXT
        curl --request POST '#{api_public_v1_dossiers_url(procedure)}' \\
             --header 'Content-Type: application/json' \\
             --data '{"identite_prenom":"#{I18n.t("views.prefill_descriptions.edit.examples.prenom")}","champ_#{type_de_champ_text.to_typed_id_for_query}":"Texte court","champ_#{prefill_type_de_champ_epci.to_typed_id_for_query}":["01","200042935"],"champ_#{type_de_champ_repetition.to_typed_id_for_query}":[{"champ_#{text_repetition.to_typed_id_for_query}":"Texte court","champ_#{integer_repetition.to_typed_id_for_query}":"42","champ_#{region_repetition.to_typed_id_for_query}":"53"},{"champ_#{text_repetition.to_typed_id_for_query}":"Texte court","champ_#{integer_repetition.to_typed_id_for_query}":"42","champ_#{region_repetition.to_typed_id_for_query}":"53"}]}'
      TEXT
    end

    before do
      prefill_description.update(selected_type_de_champ_ids: [type_de_champ_text.id, type_de_champ_epci.id, type_de_champ_repetition.id], identity_items_selected: "prenom")
    end

    it "builds the query to create a new prefilled dossier" do
      expect(prefill_description.prefill_query).to eq(expected_query)
    end
  end
end
