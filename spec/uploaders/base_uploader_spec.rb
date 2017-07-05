require 'spec_helper'

describe BaseUploader do
  let(:uploader) { described_class.new }

  describe '#cache_dir' do
    subject { uploader.cache_dir }

    context 'when rails env is not production' do
      it { is_expected.to eq '/tmp/tps-dev-cache' }
    end

    context 'when rails env is not production' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      end

      it { is_expected.to eq '/tmp/tps-cache' }
    end
  end
end
