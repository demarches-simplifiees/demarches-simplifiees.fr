# frozen_string_literal: true

describe Column do
  let(:procedure_id) { 1 }
  let(:table) { 'test_table' }
  let(:column_name) { 'test_column' }
  let(:label) { 'Test Label' }
  let(:type) { :text }
  let(:filterable) { true }
  let(:displayable) { true }
  let(:options_for_select) { [] }

  let(:column) { Column.new(procedure_id:, table:, column: column_name, label:, type:, filterable:, displayable:, options_for_select:) }

  describe '#label_for_value' do
    context 'when value is NOT_FILLED_VALUE' do
      it 'returns the not provided translation' do
        expect(column.label_for_value(Column::NOT_FILLED_VALUE)).to eq(I18n.t('activerecord.attributes.type_de_champ.not_filled'))
      end
    end

    context 'when options_for_select is present and value matches' do
      let(:options_for_select) { [['Option 1', 'one'], ['Option 2', 'two']] }
      it 'returns the label for the matching value' do
        expect(column.label_for_value('one')).to eq('Option 1')
        expect(column.label_for_value('two')).to eq('Option 2')
      end
    end
  end
end
