# frozen_string_literal: true

describe ColumnType do
  let(:type) { ColumnType.new }

  describe 'cast' do
    it 'from Column' do
      column = Column.new(procedure_id: 1, table: 'table', column: 'column')
      expect(type.cast(column)).to eq(column)
    end

    it 'from nil' do
      expect(type.cast(nil)).to eq(nil)
    end

    describe 'from form' do
      it 'with valid column id' do
        column = Column.new(procedure_id: 1, table: 'table', column: 'column')

        expect(Column).to receive(:find).with(column.h_id).and_return(column)
        expect(type.cast(column.id)).to eq(column)
      end

      it 'with invalid column id' do
        expect { type.cast('invalid') }.to raise_error(JSON::ParserError)

        id = { procedure_id: 'invalid', column_id: 'nop' }.to_json
        expect { type.cast(id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'from db' do
      it 'with valid column id' do
        column = Column.new(procedure_id: 1, table: 'table', column: 'column')
        expect(Column).to receive(:find).with(column.h_id).and_return(column)
        expect(type.cast(column.h_id)).to eq(column)
      end

      it 'with invalid column id' do
        h_id = { procedure_id: 'invalid', column_id: 'nop' }
        expect { type.cast(h_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'deserialize' do
    context 'with valid value' do
      it 'works' do
        column = Column.new(procedure_id: 1, table: 'table', column: 'column')
        expect(Column).to receive(:find).with(column.h_id).and_return(column)

        expect(type.deserialize(column.h_id)).to eq(column)
      end
    end
  end

  describe 'serialize' do
    it 'with SortedColumn' do
      column = Column.new(procedure_id: 1, table: 'table', column: 'column')
      expect(type.serialize(column)).to eq(column.h_id.to_json)
    end

    it 'with nil' do
      expect(type.serialize(nil)).to eq(nil)
    end

    it 'with invalid value' do
      expect { type.serialize('invalid') }.to raise_error(ArgumentError)
    end
  end
end
