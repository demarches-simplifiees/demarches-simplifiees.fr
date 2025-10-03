# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValueNormalizer do
  describe '.normalize' do
    it 'returns nil when given nil' do
      expect(described_class.normalize(nil)).to be_nil
    end

    it 'coerces objects to strings before normalizing' do
      expect(described_class.normalize(12)).to eq('12')
    end

    it 'normalizes carriage returns into newlines' do
      expect(described_class.normalize("foo\r\nbar\rbaz\nqux")).to eq("foo\nbar\nbaz\nqux")
    end

    it 'removes non printable control characters' do
      value = "start\u0000mid\u0007end"
      expect(described_class.normalize(value)).to eq('startmidend')
    end

    it 'keeps tabulations intact' do
      expect(described_class.normalize("foo\tbar")).to eq("foo\tbar")
    end

    it 'maps over arrays recursively' do
      input = ["foo\r\n", "bar\u0000", ["baz\r"]]
      expect(described_class.normalize(input)).to eq(["foo\n", 'bar', ["baz\n"]])
    end

    it 'transforms hash values recursively' do
      input = { operator: 'match', value: ["foo\r\nbar", nil] }
      expect(described_class.normalize(input)).to eq({ operator: 'match', value: ["foo\nbar", nil] })
    end
  end
end
