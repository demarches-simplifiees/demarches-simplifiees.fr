# frozen_string_literal: true

module Maintenance
  class HelpscoutDeleteOldCustomersTask < MaintenanceTasks::Task
    # Delete Helpscout customers not seen in the last 2 years
    # with any conversations, and any data related with GPDR compliance.
    # Respects the Helpscout API rate limit (200 calls per minute).

    MODIFIED_BEFORE = 2.years.freeze

    throttle_on(backoff: 1.minute) do
      limit = Rails.cache.read(Helpscout::API::RATELIMIT_KEY)
      limit.present? && limit.to_i <= 26 # check is made before each process but not before listing each page. External activity can affect the rate limit.
    end

    def count
      _customers, pagination = api.list_old_customers(modified_before)

      pagination[:totalElements]
    end

    # Because customers are deleted progressively,
    # ignore cursor and always pick the first page
    def enumerator_builder(cursor:)
      Enumerator.new do |yielder|
        loop do
          customers, pagination = api.list_old_customers(modified_before)
          customers.each do |customer|
            yielder.yield(customer[:id], nil) # don't care about cursor parameter
          end

          # "number" is the current page (always 1 in our case)
          # iterate until there are no remaining pages
          break if pagination[:totalPages] == 0 || pagination[:totalPages] == pagination[:number]
        end
      end
    end

    def process(customer_id)
      api.delete_customer(customer_id)
    rescue Helpscout::API::RateLimitError # despite throttle and counter, race conditions sometimes lead to rate limit hit
      sleep 1.minute
      retry
    end

    private

    def api
      @api ||= Helpscout::API.new
    end

    def modified_before
      MODIFIED_BEFORE.ago.utc.beginning_of_day
    end
  end
end
