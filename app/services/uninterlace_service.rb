# frozen_string_literal: true

class UninterlaceService
  def process(file)
    uninterlace_png(file)
  end

  private

  def uninterlace_png(uploaded_file)
    if interlaced?(uploaded_file.to_path)
      chunky_img = ChunkyPNG::Image.from_io(uploaded_file.to_io)
      chunky_img.save(uploaded_file.to_path, interlace: false)
      uploaded_file.reopen(uploaded_file.to_path, 'rb')
    end
    uploaded_file
  end

  def interlaced?(png_path)
    png = MiniMagick::Image.open(png_path)
    png.data["interlace"] != "None"
  end
end
