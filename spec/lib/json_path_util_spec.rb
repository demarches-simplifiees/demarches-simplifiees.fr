# frozen_string_literal: true

describe JSONPathUtil do
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

  describe '.extract_key_after_array' do
    it 'returns the string after the first bracket' do
      expect(JSONPathUtil.extract_key_after_array('foo[123].baz')).to eq('.baz')
    end
    it 'returns the string after the first bracket' do
      expect(JSONPathUtil.extract_key_after_array('foo[123].bar.baz')).to eq('.bar.baz')
    end
  end

  describe '.extract_array_name' do
    it 'returns the substring before the first bracket' do
      expect(JSONPathUtil.extract_array_name('foo[123].baz')).to eq('foo')
      expect(JSONPathUtil.extract_array_name('data[0].key')).to eq('data')
      expect(JSONPathUtil.extract_array_name('array[42]')).to eq('array')
    end
  end
end
