RSpec.describe AutoRotateService do
  let(:image) { file_fixture("image-rotated.jpg") }
  let(:image_no_exif) { file_fixture("image-no-exif.jpg") }
  let(:image_no_rotation) { file_fixture("image-no-rotation.jpg") }
  let(:auto_rotate_service) { AutoRotateService.new }

  describe '#process' do
    it 'returns a tempfile if auto_rotate succeeds' do
      Tempfile.create do |output|
        result = auto_rotate_service.process(image, output)
        expect(MiniMagick::Image.new(image.to_path)["%[orientation]"]).to eq('LeftBottom')
        expect(MiniMagick::Image.new(output.to_path)["%[orientation]"]).to eq('TopLeft')
        expect(result.size).to be_between(image.size / 1.2, image.size)
      end
    end

    it 'returns nil if image does not need to be return' do
      Tempfile.create do |output|
        result = auto_rotate_service.process(image_no_rotation, output)
        expect(MiniMagick::Image.new(image_no_rotation.to_path)["%[orientation]"]).to eq('TopLeft')
        expect(result).to eq nil
      end
    end

    it 'returns nil if no exif info on image' do
      Tempfile.create do |output|
        result = auto_rotate_service.process(image_no_exif, output)
        expect(MiniMagick::Image.new(image_no_exif.to_path)["%[orientation]"]).to eq('Undefined')
        expect(result).to eq nil
      end
    end
  end
end
