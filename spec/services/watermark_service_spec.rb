# frozen_string_literal: true

RSpec.describe WatermarkService do
  let(:image) { file_fixture("logo_test_procedure.png") }
  let(:watermark_service) { WatermarkService.new }

  describe '#process' do
    it 'returns a tempfile if watermarking succeeds' do
      Tempfile.create do |output|
        watermark_service.process(image, output)
        # output size should always be a little greater than input size
        expect(output.size).to be_between(image.size, image.size * 1.5)
      end
    end

    it 'returns nil if metadata is blank' do
      allow(watermark_service).to receive(:image_metadata).and_return(nil)

      Tempfile.create do |output|
        expect(watermark_service.process(image.to_path, output)).to be_nil
        expect(output.size).to eq(0)
      end
    end
  end
end
