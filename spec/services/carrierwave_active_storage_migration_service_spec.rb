require 'spec_helper'

describe CarrierwaveActiveStorageMigrationService do
  let(:service) { CarrierwaveActiveStorageMigrationService.new }

  describe '#hex_to_base64' do
    it { expect(service.hex_to_base64('deadbeef')).to eq('3q2+7w==') }
  end

  describe '.make_blob' do
    let(:pj) { create(:piece_justificative, :rib, updated_at: Time.zone.local(2019, 01, 01, 12, 00)) }
    let(:identify) { false }

    before do
      allow(service).to receive(:checksum).and_return('cafe')
    end

    subject(:blob) { service.make_blob(pj.content, pj.updated_at.iso8601, filename: pj.original_filename, identify: identify) }

    it { expect(blob.created_at).to eq pj.updated_at }

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

  describe '.make_empty_blob' do
    let(:pj) { create(:piece_justificative, :rib, updated_at: Time.zone.local(2019, 01, 01, 12, 00)) }

    before 'set the underlying stored file as missing' do
      allow(pj.content.file).to receive(:file).and_return(nil)
    end

    subject(:blob) { service.make_empty_blob(pj.content, pj.updated_at.iso8601, filename: pj.original_filename) }

    it { expect(blob.created_at).to eq pj.updated_at }

    it 'marks the blob as already scanned by the antivirus' do
      expect(blob.metadata[:virus_scan_result]).to eq(ActiveStorage::VirusScanner::SAFE)
    end

    it 'sets the blob MIME type from the file' do
      expect(blob.identified).to be true
      expect(blob.content_type).to eq 'application/pdf'
    end

    context 'when the file metadata are also missing' do
      before do
        allow(pj).to receive(:original_filename).and_return(nil)
        allow(pj.content).to receive(:content_type).and_return(nil)
      end

      it 'fallbacks on default values' do
        expect(blob.filename).to eq pj.content.filename
        expect(blob.content_type).to eq 'text/plain'
      end
    end
  end

  describe '.fix_content_type' do
    let(:pj) { create(:piece_justificative, :rib, updated_at: Time.zone.local(2019, 01, 01, 12, 00)) }
    let(:blob) { service.make_empty_blob(pj.content, pj.updated_at.iso8601, filename: pj.original_filename) }

    context 'when the request is ok' do
      it 'succeeds' do
        expect(blob.service).to receive(:change_content_type).and_return(true)
        expect { service.fix_content_type(blob) }.not_to raise_error
      end
    end

    context 'when the request fails initially' do
      it 'retries the request' do
        expect(blob.service).to receive(:change_content_type).and_raise(StandardError).ordered
        expect(blob.service).to receive(:change_content_type).and_return(true).ordered
        expect { service.fix_content_type(blob, retry_delay: 0.01) }.not_to raise_error
      end
    end

    context 'when the request fails too many times' do
      it 'gives up' do
        expect(blob.service).to receive(:change_content_type).and_raise(StandardError).thrice
        expect { service.fix_content_type(blob, retry_delay: 0.01) }.to raise_error(StandardError)
      end
    end
  end
end
