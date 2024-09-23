# frozen_string_literal: true

describe SortedColumn do
  let(:column) { Column.new(procedure_id: 1, table: 'table', column: 'column') }
  let(:sorted_column) { SortedColumn.new(column: column, order: 'asc') }

  describe '==' do
    it 'returns true for the same sorted column' do
      other = SortedColumn.new(column: column, order: 'asc')
      expect(sorted_column == other).to eq(true)
    end

    it 'returns false if the order is different' do
      other = SortedColumn.new(column: column, order: 'desc')
      expect(sorted_column == other).to eq(false)
    end

    it 'returns false if the column is different' do
      other_column = Column.new(procedure_id: 1, table: 'table', column: 'other')
      other = SortedColumn.new(column: other_column, order: 'asc')
      expect(sorted_column == other).to eq(false)
    end

    it 'returns false if the other is nil' do
      expect(sorted_column == nil).to eq(false)
    end
  end
end
