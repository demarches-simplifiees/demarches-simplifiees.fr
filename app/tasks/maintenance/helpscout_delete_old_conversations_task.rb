# frozen_string_literal: true

module Maintenance
  class HelpscoutDeleteOldConversationsTask < MaintenanceTasks::Task
    # Delete Helpscout conversations not modified in the last 2 years, given a status.
    # In order to delete all conversations, this task must be invoked 4 times
    # for the 4 status: active, closed, spam, pending.
    # Respects the Helpscount API rate limit (200 calls per minute).

    attribute :status, :string # active, closed, spam, or pending
    validates :status, presence: true

    MODIFIED_BEFORE = 2.years.freeze

    throttle_on(backoff: 1.minute) do
      limit = Rails.cache.read(Helpscout::API::RATELIMIT_KEY)
      limit.present? && limit.to_i <= 26 # check is made before each process but not before listing each page. External activity can affect the rate limit.
    end

    def count
      _conversations, pagination = api.list_old_conversations(status, modified_before)

      pagination[:totalElements]
    end

    # Because conversations are deleted progressively,
    # ignore cursor and always pick the first page
    def enumerator_builder(cursor:)
      Enumerator.new do |yielder|
        loop do
          conversations, pagination = api.list_old_conversations(status, modified_before)
          conversations.each do |conversation|
            yielder.yield(conversation[:id], nil) # don't care about cursor parameter
          end

          # "number" is the current page (always 1 in our case)
          # iterate until there are no remaining pages
          break if pagination[:totalPages] == 0 || pagination[:totalPages] == pagination[:number]
        end
      end
    end

    def process(conversation_id)
      @api.delete_conversation(conversation_id)
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
