RSpec.describe AutoRotateService do
  let(:image) { file_fixture("image-rotated.jpg") }
  let(:auto_rotate_service) { AutoRotateService.new }

  describe '#process' do
    it 'returns a tempfile if auto_rotate succeeds' do
      Tempfile.create do |output|
        auto_rotate_service.process(image, output)
        expect(MiniMagick::Image.new(image.to_path)["%[orientation]"]).to eq('LeftBottom')
        expect(MiniMagick::Image.new(output.to_path)["%[orientation]"]).to eq('TopLeft')
        expect(output.size).to be_between(image.size / 1.2, image.size)
      end
    end
  end
end
