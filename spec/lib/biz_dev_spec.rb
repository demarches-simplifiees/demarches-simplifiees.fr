require 'spec_helper'

describe BizDev, lib: true do
  let(:first_biz_dev_id) { BizDev::PIPEDRIVE_ID }
  let(:non_biz_dev_id) { first_biz_dev_id - 1 }

  it { expect(BizDev::PIPEDRIVE_ID).not_to eq(non_biz_dev_id) }

  describe '#full_name' do
    subject { described_class.full_name(administration_id) }

    context 'when administration is a business developer' do
      let(:administration_id) { first_biz_dev_id }

      it { is_expected.not_to be_empty }
    end

    context 'when administration is not a business developer' do
      let(:administration_id) { non_biz_dev_id }

      it { is_expected.not_to be_empty }
    end
  end

  describe '#pipedrive_id' do
    subject { described_class.pipedrive_id(administration_id) }

    context 'when administration is a business developer' do
      let(:administration_id) { first_biz_dev_id }

      it { is_expected.to be > 0 }
    end

    context 'when administration is not a business developer' do
      let(:administration_id) { non_biz_dev_id }

      it { is_expected.to be > 0 }
    end
  end
end
