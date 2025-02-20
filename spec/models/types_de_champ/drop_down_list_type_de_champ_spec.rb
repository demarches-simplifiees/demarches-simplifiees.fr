# frozen_string_literal: true

describe TypesDeChamp::DropDownListTypeDeChamp do
  describe '#columns' do
    let(:procedure) { create(:procedure, types_de_champ_public:) }
    let(:types_de_champ_public) { [{ type: :drop_down_list }] }
    let(:referentiel) { create(:csv_referentiel, :with_items) }

    context 'when referentiel_mode is true' do
      let(:dropdown_list_tdc) { procedure.active_revision.types_de_champ.first }

      context 'when an item has nil for a specific header' do
        before do
          dropdown_list_tdc.update(referentiel:, drop_down_mode: 'advanced')

          item = dropdown_list_tdc.referentiel.items.first
          data = item.data
          data['row']['calorie_kcal'] = nil
          item.update(data:)
        end

        let(:calorie_column) { dropdown_list_tdc.columns(procedure:).find { _1.label =~ /calorie/ } }

        it { expect(calorie_column.options_for_select).to eq(["100", "170"]) }
      end
    end
  end
end
