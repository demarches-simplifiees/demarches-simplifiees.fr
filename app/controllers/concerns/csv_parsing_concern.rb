# frozen_string_literal: true

module CsvParsingConcern
  extend ActiveSupport::Concern

  CSV_MAX_SIZE = 1.megabyte
  CSV_MAX_LINES = 5_000
  CSV_ACCEPTED_CONTENT_TYPES = [
    "text/csv",
    "application/vnd.ms-excel",
  ]

  included do
    private

    def csv_file?
      CSV_ACCEPTED_CONTENT_TYPES.include?(referentiel_file.content_type) ||
        CSV_ACCEPTED_CONTENT_TYPES.include?(marcel_content_type)
    end

    def parse_csv(file, strings_as_keys: true, keep_original_headers: false, convert_values_to_numeric: false)
      raw_content = file.read

      utf8_content = ensure_utf8(raw_content)

      Tempfile.create(['referentiel', '.csv'], encoding: 'UTF-8') do |tempfile|
        tempfile.write(utf8_content)
        tempfile.rewind

        begin
          SmarterCSV.process(
            tempfile.path,
            strings_as_keys:,
            keep_original_headers:,
            convert_values_to_numeric:
          )
        rescue *[CSV::MalformedCSVError, SmarterCSV::NoColSepDetected, ArgumentError]
          []
        end
      end
    end

    def ensure_utf8(content)
      detection = CharlockHolmes::EncodingDetector.detect(content)
      source_encoding = detection[:encoding] || 'Windows-1252'
      CharlockHolmes::Converter.convert(content, source_encoding, 'UTF-8')
    end
  end
end
