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
        '$.foo.baz{0}.qux' => 'valeur',
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
        "$.data{0}.key" => "value"
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
        "$.ext_ids{0}.id",
        "$.ext_ids{0}.source",
        "$.ext_ids{0}.created_at",
        "$.ext_ids{0}.source_version",
        "$.addresses{0}.id",
        "$.addresses{0}.source",
        "$.addresses{0}.street",
        "$.addresses{0}.city_name",
        "$.addresses{0}.street_rep",
        "$.addresses{0}.city_zipcode",
        "$.addresses{0}.street_number",
        "$.addresses{0}.city_insee_code",
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
end
