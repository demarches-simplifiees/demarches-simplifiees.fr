# frozen_string_literal: true

describe Logic::Or do
  include Logic

  describe '#compute' do
    it { expect(or_from([true, true, true]).compute).to be true }
    it { expect(or_from([true, true, false]).compute).to be true }
    it { expect(or_from([false, false, false]).compute).to be false }
    it { expect(ds_or([ds_group(ds_or([constant(false), constant(true)])), ds_group(ds_and([constant(false), constant(false)]))]).compute).to be true }
    it { expect(ds_or([ds_group(ds_or([constant(false), constant(false)])), ds_group(ds_and([constant(false), constant(false)]))]).compute).to be false }
    it { expect(ds_or([ds_group(ds_or([constant(false), constant(true)])), ds_group(ds_or([constant(true)]))]).compute).to be true }
  end

  describe '#to_s' do
    it { expect(or_from([true, false, true]).to_s).to eq "(Oui || Non || Oui)" }
    it { expect(ds_or([ds_group(ds_or([constant(false), constant(true)])), ds_group(ds_and([constant(false), constant(false)]))]).to_s([])).to eq "((Non || Oui) || (Non && Non))" }
  end

  def or_from(boolean_to_constants)
    ds_or(boolean_to_constants.map { |b| constant(b) })
  end
end
