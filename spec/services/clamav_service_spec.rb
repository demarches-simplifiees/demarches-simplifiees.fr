require 'spec_helper'

describe ClamavService do
  describe '.safe_file?' do
    let(:path_file) { '/tmp/plop.txt' }

    subject { ClamavService.safe_file?(path_file) }

    before do
      client = double("ClamAV::Client", execute: [response])
      allow(ClamAV::Client).to receive(:new).and_return(client)
      allow(FileUtils).to receive(:chmod).with(0666, path_file).and_return(true)
    end

    context 'When response type is ClamAV::SuccessResponse' do
      let(:response) { ClamAV::SuccessResponse.new("OK") }
      it { expect(subject).to eq(true) }
    end

    context 'When response type is ClamAV::VirusResponse' do
      let(:response) { ClamAV::VirusResponse.new("KO", "VirusN4ame") }
      it { expect(subject).to eq(false) }
    end

    context 'When response type is ClamAV::ErrorResponse' do
      let(:response) { ClamAV::ErrorResponse.new("File not found") }
      it { expect { subject }.to raise_error("ClamAV ErrorResponse : File not found") }
    end
  end
end
