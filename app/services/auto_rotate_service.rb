class AutoRotateService
  def process(file, output)
    auto_rotate_image(file, output)
  end

  private

  def auto_rotate_image(file, output)
    image = MiniMagick::Image.new(file.to_path)

    return nil if !image.valid?

    case image["%[orientation]"]
    when 'LeftBottom'
      rotate_image(file, output, 90)
    when 'BottomRight'
      rotate_image(file, output, 180)
    when 'RightTop'
      rotate_image(file, output, 270)
    else
      nil
    end
  end

  def rotate_image(file, output, degree)
    MiniMagick::Tool::Convert.new do |convert|
      convert << file.to_path
      convert.rotate(degree)
      convert.auto_orient
      convert << output.to_path
    end
    output
  end
end
