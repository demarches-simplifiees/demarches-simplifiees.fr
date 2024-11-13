# frozen_string_literal: true

class GenerateOpenDataCsvService
  def self.save_csv_to_tmp(file_name, headers, data)
    f = Tempfile.create(["#{file_name}_#{date_last_month}", '.csv'], 'tmp')
    f << generate_csv(headers, data)
    f.rewind
    yield f if block_given?
    f.close
  end

  private

  def self.date_last_month
    Date.today.prev_month.strftime("%B %Y")
  end

  def self.generate_csv(headers, data)
    data.map! { |d| d.unshift(date_last_month) }
    SpreadsheetArchitect.to_csv(headers: headers, data: data)
  end
end
