require 'spec_helper'

describe BaseUploader do
  let(:uploader) { described_class.new }

  describe '#cache_dir' do
    subject { uploader.cache_dir }

    it { is_expected.to eq '/tmp/tps-test-cache' }
  end
end
