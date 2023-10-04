# frozen_string_literal: true

class TableRowSelector::API
  class << self
    def available_tables
      engine&.available_tables
    end

    def search(domain_id, term)
      engine&.search(domain_id, term)
    end

    def fetch_row(external_id)
      table, id = external_id.split(':')
      engine.fetch_row(table, id)
    end

    def engine
      @engine ||= ENV['API_BASEROW_URL'].present? ? TableRowSelector::BaserowAPI : nil
    end
  end
end
