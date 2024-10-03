# frozen_string_literal: true

describe Logic::And do
  include Logic

  describe '#compute' do
    it { expect(and_from([true, true, true]).compute).to be true }
    it { expect(and_from([true, true, false]).compute).to be false }
    it { expect(and_from([true, true, false]).compute).to be false }
    it { expect(ds_and([ds_group(ds_or([constant(false), constant(true)])), ds_group(ds_or([constant(false), constant(false)]))]).compute).to be false }
    it { expect(ds_and([ds_group(ds_or([constant(false), constant(true)])), ds_group(ds_or([constant(true), constant(false)]))]).compute).to be true }
    it { expect(ds_and([ds_group(ds_or([constant(false), constant(true)])), ds_group(ds_or([constant(false)]))]).compute).to be false }
  end

  describe '#to_s' do
    it { expect(and_from([true, false, true]).to_s([])).to eq "(Oui && Non && Oui)" }
    it { expect(ds_and([ds_group(ds_or([constant(false), constant(true)])), ds_group(ds_or([constant(true), constant(false)]))]).to_s([])).to eq "((Non || Oui) && (Oui || Non))" }
  end

  def and_from(boolean_to_constants)
    ds_and(boolean_to_constants.map { |b| constant(b) })
  end
end
