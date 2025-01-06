# frozen_string_literal: true

module ZipHelpers
  def read_zip_entries(file)
    files = []
    Zip::File.open(file) do |zip|
      files = zip.entries.map(&:name)
    end
    files
        end

  def read_zip_file_content(file, entry_name)
    content = nil
    Zip::File.open(file) do |zip|
      entry = zip.find_entry(entry_name)
      content = entry.get_input_stream.read if entry
    end
    content
  end
end
