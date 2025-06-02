# frozen_string_literal: true

describe ExportItemType do
  let(:type) { ExportItemType.new }

  describe 'cast' do
    it 'from ExportItem' do
      export_item = ExportItem.new(template: { foo: 'bar' }, enabled: true, stable_id: 42)
      expect(type.cast(export_item)).to eq(export_item)
    end

    it 'from nil' do
      expect(type.cast(nil)).to eq(nil)
    end

    it 'from db' do
      h = { template: { foo: 'bar' }, enabled: true, stable_id: 42 }
      expect(type.cast(h)).to eq(ExportItem.new(template: { foo: 'bar' }, enabled: true, stable_id: 42))
    end

    it 'from form' do
      h = { template: '{"foo":{"bar":"zob"}}' }
      expect(type.cast(h)).to eq(ExportItem.new(template: { foo: { bar: 'zob' } }, enabled: false))

      h = { template: '{"foo":{"bar":"zob"}}', enabled: 'true' }
      expect(type.cast(h)).to eq(ExportItem.new(template: { foo: { bar: 'zob' } }, enabled: true))

      h = { template: '{"foo":{"bar":"zob"}}', stable_id: '42' }
      expect(type.cast(h)).to eq(ExportItem.new(template: { foo: { bar: 'zob' } }, enabled: false, stable_id: 42))

      h = { template: '{"foo":{"bar":"zob"}}', enabled: 'true', stable_id: '42' }
      expect(type.cast(h)).to eq(ExportItem.new(template: { foo: { bar: 'zob' } }, enabled: true, stable_id: 42))
    end

    it 'from invalid value' do
      expect { type.cast('invalid value') }.to raise_error(NoMatchingPatternError)
    end
  end

  describe 'deserialize' do
    it 'from nil' do
      expect(type.deserialize(nil)).to eq(nil)
    end

    it 'from db' do
      h = { template: { foo: 'bar' }, enabled: true, stable_id: 42 }
      expect(type.deserialize(JSON.generate(h))).to eq(ExportItem.new(template: { foo: 'bar' }, enabled: true, stable_id: 42))
    end
  end

  describe 'serialize' do
    it 'from ExportItem' do
      export_item = ExportItem.new(template: { foo: 'bar' }, enabled: true, stable_id: 42)
      expect(type.serialize(export_item)).to eq('{"template":{"foo":"bar"},"enabled":true,"stable_id":42}')
    end
  end
end
