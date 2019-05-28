require 'spec_helper'

describe CarrierwaveActiveStorageMigrationService do
  let(:service) { CarrierwaveActiveStorageMigrationService.new }

  describe '#hex_to_base64' do
    it { expect(service.hex_to_base64('deadbeef')).to eq('3q2+7w==') }
  end

  describe '.make_blob' do
    let(:pj) { create(:piece_justificative, :rib) }
    let(:identify) { false }

    before do
      allow(service).to receive(:checksum).and_return('cafe')
    end

    subject(:blob) { service.make_blob(pj.content, pj.updated_at.iso8601, filename: pj.original_filename, identify: identify) }

    it 'marks the blob as already scanned by the antivirus' do
      expect(blob.metadata[:virus_scan_result]).to eq(ActiveStorage::VirusScanner::SAFE)
    end

    it 'sets the blob MIME type from the file' do
      expect(blob.identified).to be true
      expect(blob.content_type).to eq 'application/pdf'
    end

    context 'when asking for explicit MIME type identification' do
      let(:identify) { true }

      it 'marks the file as needing MIME type detection' do
        expect(blob.identified).to be false
      end
    end
  end
end
