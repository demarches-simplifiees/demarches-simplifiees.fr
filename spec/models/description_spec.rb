RSpec.describe Description, type: :model do
  include Rails.application.routes.url_helpers

  describe '#update' do
    let(:description) { described_class.new(build(:procedure)) }
    let(:type_de_champ_ids) { ["1", "2"] }
    subject(:update) { description.update(attributes) }

    context 'when type_de_champ_ids are given' do
      let(:attributes) { { type_de_champ_ids: type_de_champ_ids } }

      it 'populate type_de_champ_ids' do
        expect { update }.to change { description.type_de_champ_ids }.from([]).to(type_de_champ_ids)
      end
    end
  end

  describe '#types_de_champ' do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }
    let(:description) { described_class.new(procedure) }

    it { expect(description.types_de_champ).to match([type_de_champ]) }
  end

  describe '#include?' do
    let(:description) { described_class.new(build(:procedure)) }
    let(:type_de_champ_id) { 1 }
    subject(:included) { description.include?(type_de_champ_id) }

    context 'when the id has been added to the description' do
      before { description.update(type_de_champ_ids: ["1"]) }

      it { expect(included).to eq(true) }
    end

    context 'when the id has not be added to the description' do
      it { expect(included).to eq(false) }
    end
  end

  describe '#too_long?' do
    let(:procedure) { create(:procedure) }
    let(:description) { described_class.new(procedure) }

    subject(:too_long) { description.too_long? }

    before { description.update(type_de_champ_ids: create_list(:type_de_champ_text, type_de_champs_count, procedure: procedure).map(&:id)) }

    context 'when the prefill link is too long' do
      let(:type_de_champs_count) { 60 }

      it { expect(too_long).to eq(true) }
    end

    context 'when the prefill link is not too long' do
      let(:type_de_champs_count) { 2 }

      it { expect(too_long).to eq(false) }
    end
  end

  describe '#to_s' do
    let(:procedure) { create(:procedure) }
    let(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }
    let(:description) { described_class.new(procedure) }

    before { description.update(type_de_champ_ids: [type_de_champ.id]) }

    it "builds the URL to create a new prefilled dossier" do
      expect(description.to_s).to eq(
        new_dossier_url(
          procedure_id: procedure.id,
          "champ_#{type_de_champ.to_typed_id}" => type_de_champ.libelle
        )
      )
    end
  end
end
