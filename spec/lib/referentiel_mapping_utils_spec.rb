# frozen_string_literal: true

require 'rails_helper'

describe ReferentielMappingUtils do
  describe ".array_of_supported_simple_types?" do
    it "returns true for array of strings" do
      expect(described_class.array_of_supported_simple_types?(["a", "b"]))
        .to eq(true)
    end
    it "returns true for array of ints" do
      expect(described_class.array_of_supported_simple_types?([1, 2, 3])).to eq(true)
    end
    it "returns true for array of floats" do
      expect(described_class.array_of_supported_simple_types?([1.1, 2.2])).to eq(true)
    end
    it "returns true for mixed simple types" do
      expect(described_class.array_of_supported_simple_types?([1, "a", 2.2])).to eq(true)
    end
    it "returns false for array with hash" do
      expect(described_class.array_of_supported_simple_types?([{ a: 1 }, "b"]))
        .to eq(false)
    end
    it "returns false for array with array" do
      expect(described_class.array_of_supported_simple_types?([[1, 2], "b"]))
        .to eq(false)
    end
    it "returns false for non-array" do
      expect(described_class.array_of_supported_simple_types?("a")).to eq(false)
      expect(described_class.array_of_supported_simple_types?(nil)).to eq(false)
    end
  end
end
