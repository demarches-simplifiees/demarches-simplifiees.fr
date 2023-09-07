RSpec.describe WatermarkService do
  let(:image) { file_fixture("logo_test_procedure.png") }
  let(:watermark_service) { WatermarkService.new }

  describe '#process' do
    it 'returns a tempfile if watermarking succeeds' do
      output = watermark_service.process(image.to_path)
      expect(output).to be_a(Tempfile)
      expect(File.extname(output)).to eq(image.extname)

      # output size should always be a little greater than input size
      expect(output.size).to be_between(image.size, image.size * 1.5)
    end

    it 'returns nil if metadata is blank' do
      allow(watermark_service).to receive(:image_metadata).and_return(nil)
      expect(watermark_service.process(image.to_path)).to be_nil
    end
  end
end
