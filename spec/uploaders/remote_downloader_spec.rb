require 'spec_helper'

describe RemoteDownloader do
  let(:filename) { 'file_name.pdf' }

  subject { described_class.new filename }

  describe '#url' do
    it { expect(subject.url).to eq 'https://static.demarches-simplifiees.fr/tps_dev/file_name.pdf' }

    context 'no filename' do
      let(:filename) { nil }

      it { expect(subject.url).to be_nil }
    end
  end
end
