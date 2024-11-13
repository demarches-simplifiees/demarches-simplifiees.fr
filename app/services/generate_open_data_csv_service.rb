# frozen_string_literal: true

class GenerateOpenDataCsvService
  def self.save_csv_to_tmp(file_name, headers, data)
    Tempfile.create(["#{file_name}_#{date_last_month}", '.csv'], 'tmp') do |file|
      file << SpreadsheetArchitect.to_csv(headers:, data:)
      file.rewind
      yield file if block_given?
    end
  end
end
