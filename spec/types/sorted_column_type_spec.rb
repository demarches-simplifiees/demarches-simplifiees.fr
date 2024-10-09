# frozen_string_literal: true

describe SortedColumnType do
  let(:type) { SortedColumnType.new }

  describe 'cast' do
    it 'from SortedColumn' do
      column = Column.new(procedure_id: 1, table: 'table', column: 'column')
      sorted_column = SortedColumn.new(column:, order: 'asc')
      expect(type.cast(sorted_column)).to eq(sorted_column)
    end

    it 'from nil' do
      expect(type.cast(nil)).to eq(nil)
    end

    describe 'from form' do
      it 'with valid column id' do
        column = Column.new(procedure_id: 1, table: 'table', column: 'column')
        h = { order: 'asc', id: column.id }

        expect(Column).to receive(:find).with(column.h_id).and_return(column)
        expect(type.cast(h)).to eq(SortedColumn.new(column: column, order: 'asc'))
      end

      it 'with invalid column id' do
        h = { order: 'asc', id: 'invalid' }
        expect { type.cast(h) }.to raise_error(JSON::ParserError)

        h = { order: 'asc', id: { procedure_id: 'invalid', column_id: 'nop' }.to_json }
        expect { type.cast(h) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'with invalid order' do
        column = Column.new(procedure_id: 1, table: 'table', column: 'column')
        h = { order: 'invalid', id: column.id }
        expect { type.cast(h) }.to raise_error(NoMatchingPatternError)
      end
    end
  end

  describe 'deserialize' do
    context 'with valid value' do
      it 'works' do
        column = Column.new(procedure_id: 1, table: 'table', column: 'column')
        expect(Column).to receive(:find).with(column.h_id).and_return(column)
        expect(type.deserialize({ id: column.h_id, order: 'asc' }.to_json)).to eq(SortedColumn.new(column: column, order: 'asc'))
      end
    end

    context 'with nil' do
      it { expect(type.deserialize(nil)).to eq(nil) }
    end
  end

  describe 'serialize' do
    it 'with SortedColumn' do
      column = Column.new(procedure_id: 1, table: 'table', column: 'column')
      sorted_column = SortedColumn.new(column: column, order: 'asc')
      expect(type.serialize(sorted_column)).to eq({ id: column.h_id, order: 'asc' }.to_json)
    end

    it 'with nil' do
      expect(type.serialize(nil)).to eq(nil)
    end

    it 'with invalid value' do
      expect { type.serialize('invalid') }.to raise_error(ArgumentError)
    end
  end
end
