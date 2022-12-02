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

    context 'when a type_de_champ_id to add is given' do
      let(:attributes) { { type_de_champ_ids: type_de_champ_ids, type_de_champ_id_to_add: "3" } }

      it 'adds it to type_de_champ_ids' do
        expect { update }.to change { description.type_de_champ_ids }.from([]).to(type_de_champ_ids + ["3"])
      end
    end

    context 'when a type_de_champ_id to remove is given' do
      let(:attributes) { { type_de_champ_ids: type_de_champ_ids, type_de_champ_id_to_remove: "2" } }

      it 'removes it from type_de_champ_ids' do
        expect { update }.to change { description.type_de_champ_ids }.from([]).to(type_de_champ_ids - ["2"])
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
      before { description.update(type_de_champ_id_to_add: "1") }

      it { expect(included).to eq(true) }
    end

    context 'when the id has not be added to the description' do
      it { expect(included).to eq(false) }
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
