# frozen_string_literal: true

describe JSONPath do
  describe '.hash_to_jsonpath' do
    it 'converts a nested hash into jsonpath => value pairs' do
      hash = {
        'foo' => {
          'bar' => 1,
          'baz' => [
            { 'qux' => 'valeur' }
          ]
        },
        'simple' => 'ok'
      }
      result = described_class.hash_to_jsonpath(hash)
      expect(result).to eq({
        '$.foo.bar' => 1,
        '$.foo.baz[0].qux' => 'valeur',
        '$.simple' => 'ok'
      })
    end

    it 'jsonpathify simple hash' do
      expect(described_class.hash_to_jsonpath({ "key" => "value" })).to eq({
        "$.key" => "value"
      })
    end

    it 'jsonpathify nested hash' do
      expect(described_class.hash_to_jsonpath({ "key" => { "nested" => "value" } })).to eq({
        "$.key.nested" => "value"
      })
    end

    it 'jsonpathify array in hash' do
      expect(described_class.hash_to_jsonpath({ data: [{ "key" => "value" }] })).to eq({
        "$.data[0].key" => "value"
      })
    end

    it 'jsonpathify real response' do
      rnb_json = JSON.parse(File.read('spec/fixtures/files/api_referentiel_rnb.json'))
      expect(described_class.hash_to_jsonpath(rnb_json).keys).to match_array([
        "$.point.type",
        "$.point.coordinates",
        "$.shape.type",
        "$.shape.coordinates",
        "$.rnb_id",
        "$.status",
        "$.ext_ids[0].id",
        "$.ext_ids[0].source",
        "$.ext_ids[0].created_at",
        "$.ext_ids[0].source_version",
        "$.addresses[0].id",
        "$.addresses[0].source",
        "$.addresses[0].street",
        "$.addresses[0].city_name",
        "$.addresses[0].street_rep",
        "$.addresses[0].city_zipcode",
        "$.addresses[0].street_number",
        "$.addresses[0].city_insee_code",
        "$.is_active"
      ])
    end
  end

  describe '.value' do
    let(:hash) do
      {
        'foo' => {
          'bar' => [
            { 'baz' => 'valeur' }
          ]
        },
        'simple' => 42
      }
    end

    it 'retrieves a simple value' do
      expect(described_class.value(hash, '$.simple')).to eq 42
    end

    it 'returns nil if the path is missing' do
      expect(described_class.value(hash, '$.foo.bar[1].baz')).to be_nil
    end
  end
  describe '.extract_key_after_array' do
    it 'returns the string after the first bracket' do
      expect(JSONPath.extract_key_after_array('foo[123].baz')).to eq('.baz')
    end
    it 'returns the string after the first bracket' do
      expect(JSONPath.extract_key_after_array('foo[123].bar.baz')).to eq('.bar.baz')
    end
  end
  describe '.extract_array_name' do
    it 'returns the substring before the first bracket' do
      expect(JSONPath.extract_array_name('foo[123].baz')).to eq('foo')
      expect(JSONPath.extract_array_name('data[0].key')).to eq('data')
      expect(JSONPath.extract_array_name('array[42]')).to eq('array')
    end
  end
  describe '.get_array' do
  let(:hash) do
    {
      'items' => [
        { 'id' => 1, 'name' => 'foo' },
        { 'id' => 2, 'name' => 'bar' }
      ],
      'data' => { 'not_array' => 'value' },
      'empty' => []
    }
  end

  it 'returns the array for a valid array path' do
    expect(JSONPath.get_array(hash, '$.items[0]')).to eq([
      { 'id' => 1, 'name' => 'foo' },
      { 'id' => 2, 'name' => 'bar' }
    ])
  end

  it 'returns nil if the key does not exist' do
    expect(JSONPath.get_array(hash, '$.missing[0]')).to be_nil
  end

  it 'returns the value even if it is not an array' do
    expect(JSONPath.get_array(hash, '$.data[0]')).to eq({ 'not_array' => 'value' })
  end

  it 'returns an empty array if the array is empty' do
    expect(JSONPath.get_array(hash, '$.empty[0]')).to eq([])
  end

  it 'returns nil if hash is nil' do
    expect(JSONPath.get_array(nil, '$.items[0]')).to be_nil
  end
end
end
