# frozen_string_literal: true

class GenerateOpenDataService
  def self.existing_csv(dataset, resource, headers)
    url = APIDatagouv::API.existing_file_url(dataset, resource)
    return default_csv(headers) unless url

    response = Typhoeus.get(url)
    return default_csv(headers) unless response.success?

    CSV.parse(response.body, headers: true)
  end

  def self.months_to_query(csv)
    return [Date.current.prev_month.all_month] if csv.empty?

    last_date = Date.parse("#{csv.first['mois']}-01")
    previous_month = 1.month.ago.beginning_of_month.to_date
    nb_month = (previous_month.year * 12 + previous_month.month) - (last_date.year * 12 + last_date.month)
    Array.new(nb_month) { |i| (last_date + (1 + i).month).all_month }
  end

  private

  def self.default_csv(headers)
    CSV::Table.new([], headers:)
  end
end
