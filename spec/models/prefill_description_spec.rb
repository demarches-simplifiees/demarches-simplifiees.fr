RSpec.describe PrefillDescription, type: :model do
  include Rails.application.routes.url_helpers

  describe '#update' do
    let(:prefill_description) { described_class.new(build(:procedure)) }
    let(:selected_type_de_champ_ids) { ["1", "2"] }
    subject(:update) { prefill_description.update(attributes) }

    context 'when selected_type_de_champ_ids are given' do
      let(:attributes) { { selected_type_de_champ_ids: selected_type_de_champ_ids } }

      it 'populate selected_type_de_champ_ids' do
        expect { update }.to change { prefill_description.selected_type_de_champ_ids }.from([]).to(selected_type_de_champ_ids)
      end
    end
  end

  describe '#types_de_champ' do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }
    let(:prefill_description) { described_class.new(procedure) }

    it { expect(prefill_description.types_de_champ).to match([type_de_champ]) }
  end

  describe '#include?' do
    let(:prefill_description) { described_class.new(build(:procedure)) }
    let(:type_de_champ_id) { 1 }
    subject(:included) { prefill_description.include?(type_de_champ_id) }

    context 'when the id has been added to the prefill_description' do
      before { prefill_description.update(selected_type_de_champ_ids: ["1"]) }

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

    before { prefill_description.update(selected_type_de_champ_ids: create_list(:type_de_champ_text, type_de_champs_count, procedure: procedure).map(&:id)) }

    context 'when the prefill link is too long' do
      let(:type_de_champs_count) { 60 }

      it { expect(too_long).to eq(true) }
    end

    context 'when the prefill link is not too long' do
      let(:type_de_champs_count) { 2 }

      it { expect(too_long).to eq(false) }
    end
  end

  describe '#prefill_link' do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }
    let(:prefill_description) { described_class.new(procedure) }

    before { prefill_description.update(selected_type_de_champ_ids: [type_de_champ.id]) }

    it "builds the URL to create a new prefilled dossier" do
      expect(prefill_description.prefill_link).to eq(
        commencer_url(
          path: procedure.path,
          "champ_#{type_de_champ.to_typed_id}" => type_de_champ.libelle
        )
      )
    end
  end

  describe '#prefill_query' do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }
    let(:prefill_description) { described_class.new(procedure) }
    let(:expected_query) do
      <<~TEXT
        curl --request POST '#{api_public_v1_dossiers_url}'
             --header 'Content-Type: application/json'
             --data '{"procedure_id": #{procedure.id}, "champ_#{type_de_champ.to_typed_id}": "#{type_de_champ.libelle}"}'
      TEXT
    end

    before { prefill_description.update(selected_type_de_champ_ids: [type_de_champ.id]) }

    it "builds the query to create a new prefilled dossier" do
      expect(prefill_description.prefill_query).to eq(expected_query)
    end
  end
end
