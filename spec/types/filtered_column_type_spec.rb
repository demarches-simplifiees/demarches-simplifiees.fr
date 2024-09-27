# frozen_string_literal: true

describe FilteredColumnType do
  let(:type) { FilteredColumnType.new }

  describe 'cast' do
    it 'from FilteredColumn' do
      column = Column.new(procedure_id: 1, table: 'table', column: 'column')
      filtered_column = FilteredColumn.new(column:, filter: 'filter')
      expect(type.cast(filtered_column)).to eq(filtered_column)
    end

    it 'from nil' do
      expect(type.cast(nil)).to eq(nil)
    end

    describe 'from form' do
      it 'with valid column id' do
        column = Column.new(procedure_id: 1, table: 'table', column: 'column')
        h = { filter: 'filter', id: column.id }

        expect(Column).to receive(:find).with(column.h_id).and_return(column)
        expect(type.cast(h)).to eq(FilteredColumn.new(column:, filter: 'filter'))
      end

      it 'with invalid column id' do
        h = { filter: 'filter', id: 'invalid' }
        expect { type.cast(h) }.to raise_error(JSON::ParserError)

        h = { filter: 'filter', id: { procedure_id: 'invalid', column_id: 'nop' }.to_json }
        expect { type.cast(h) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'deserialize' do
    context 'with valid value' do
      it 'works' do
        column = Column.new(procedure_id: 1, table: 'table', column: 'column')
        expect(Column).to receive(:find).with(column.h_id).and_return(column)
        expect(type.deserialize({ id: column.h_id, filter: 'filter' }.to_json)).to eq(FilteredColumn.new(column: column, filter: 'filter'))
      end
    end

    context 'with nil' do
      it { expect(type.deserialize(nil)).to eq(nil) }
    end
  end

  describe 'serialize' do
    it 'with FilteredColumn' do
      column = Column.new(procedure_id: 1, table: 'table', column: 'column')
      sorted_column = FilteredColumn.new(column: column, filter: 'filter')
      expect(type.serialize(sorted_column)).to eq({ id: column.h_id, filter: 'filter' }.to_json)
    end

    it 'with nil' do
      expect(type.serialize(nil)).to eq(nil)
    end

    it 'with invalid value' do
      expect { type.serialize('invalid') }.to raise_error(ArgumentError)
    end
  end
end
