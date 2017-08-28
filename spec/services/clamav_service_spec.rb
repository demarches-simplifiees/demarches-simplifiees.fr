require 'spec_helper'

describe ClamavService do
  describe '.safe_file?' do
    let(:path_file) { '/tmp/plop.txt' }

    subject { ClamavService.safe_file? path_file }

    before do
      client = instance_double("ClamAV::Client", :execute => [ClamAV::SuccessResponse])
      allow(ClamAV::Client).to receive(:new).and_return(client)
    end

    it 'change permission of file path' do
      allow(FileUtils).to receive(:chmod).with(0666, path_file).and_return(true)

      subject
    end
  end
end
