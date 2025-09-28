# frozen_string_literal: true

describe Logic::And do
  include Logic

  describe '#compute' do
    it do
      expect(and_from([true, true, true]).compute).to be true
      expect(and_from([true, true, false]).compute).to be false
    end
  end

  describe '#to_s' do
    it do
      expect(and_from([true, false, true]).to_s([])).to eq "(Oui && Non && Oui)"
    end
  end

  def and_from(boolean_to_constants)
    ds_and(boolean_to_constants.map { |b| constant(b) })
  end
end
