# frozen_string_literal: true

namespace :iban_data do
  IBAN_DATA_PATH = Rails.root.join('lib', 'data', 'iban')
  ECB_URL = 'https://www.ecb.europa.eu/stats/money/mfi/general/html/dla/mfi_mrr_MID/fi_mrr_csv_240930.csv'

  desc 'Refresh data from ECB Geo'
  task refresh: :environment do
    IBAN_DATA_PATH.rmtree if IBAN_DATA_PATH.exist?
    IBAN_DATA_PATH.mkpath

    response = Typhoeus.get(ECB_URL)
    csv = response.body
    base_encoding = CharlockHolmes::EncodingDetector.detect(csv)
    csv = csv.encode("UTF-8", base_encoding[:encoding], invalid: :replace, replace: "")

    data = []
    csv.each_line.with_index do |line, index|
      next if index == 0
      riad_code, bic, country, name = line.chomp.split("\t")
      if riad_code.present? && bic.present?
        data << { riad_code:, bic:, country:, name: }
      end
    end

    IBAN_DATA_PATH.join("bic.json").open('w') do |f|
      f << JSON.pretty_generate(data)
    end
  end
end
