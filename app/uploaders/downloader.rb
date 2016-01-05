require 'securerandom'

class Downloader
  BASE_PATH_DISK = File.join(Rails.root, "public/")

  def initialize(filename, filename_suffix = '')
    @filename = filename.to_s
    @filename_suffix = filename_suffix.empty? ? '' : "_#{filename_suffix}"
    @extension = @filename.split(/[.]/).last

    generate_random_base_path!

    FileUtils.cp @filename, "#{@base_path}/#{@filename_suffix}.#{@extension}"
  end

  def url
    @url ||= File.join(TPS::Application::URL, random_folder_name, "#{@filename_suffix}.#{@extension}")
  end

  protected

  attr_accessor :random_folder_name

  def generate_random_base_path!
    @base_path ||= begin
      loop do
        self.random_folder_name = SecureRandom.hex
        base_path = File.join(BASE_PATH_DISK, self.random_folder_name)
        unless File.directory?(base_path)
          Dir.mkdir(base_path)
          break base_path
        end
      end
    end
  end
end
