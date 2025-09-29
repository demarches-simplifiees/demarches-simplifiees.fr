# frozen_string_literal: true

describe Logic::Or do
  include Logic

  describe '#compute' do
    it do
      expect(or_from([true, true, true]).compute).to be true
      expect(or_from([true, true, false]).compute).to be true
      expect(or_from([false, false, false]).compute).to be false
    end
  end

  describe '#to_s' do
    it { expect(or_from([true, false, true]).to_s).to eq "(Oui || Non || Oui)" }
  end

  def or_from(boolean_to_constants)
    ds_or(boolean_to_constants.map { |b| constant(b) })
  end
end
