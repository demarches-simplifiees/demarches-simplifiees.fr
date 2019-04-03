require 'spec_helper'

describe IPService do
  describe '.ip_trusted?' do
    subject { IPService.ip_trusted?(ip) }

    context 'when the ip is nil' do
      let(:ip) { nil }

      it { is_expected.to be(false) }
    end

    context 'when the ip is defined' do
      let(:ip) { '192.168.1.10' }

      context 'when it belongs to a trusted network' do
        before do
          ENV['TRUSTED_NETWORKS'] = '10.0.0.0/8 192.168.0.0/16 bad_network'
        end

        it { is_expected.to be(true) }
      end

      context 'when it does not belong to a trusted network' do
        before do
          ENV['TRUSTED_NETWORKS'] = '10.0.0.0/8'
        end

        it { is_expected.to be(false) }
      end
    end

    context 'when a trusted network is defined' do
      before { ENV['TRUSTED_NETWORKS'] = '10.0.0.0/8' }

      context 'when the ip is nil' do
        let(:ip) { nil }

        it { is_expected.to be(false) }
      end

      context 'when the ip is badly formatted' do
        let(:ip) { 'yop' }

        it { is_expected.to be(false) }
      end
    end
  end
end
