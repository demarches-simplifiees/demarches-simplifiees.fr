# frozen_string_literal: true

module Maintenance
  module StatementsHelpersConcern
    extend ActiveSupport::Concern

    included do
      # Execute block in transaction with a local statement timeout.
      # A value of 0 disable the timeout.
      #
      # Example:
      # def collection
      #   with_statement_timeout("5min") do
      #     Dossier.all
      #   end
      # end
      def with_statement_timeout(timeout)
        ApplicationRecord.transaction do
          ApplicationRecord.connection.execute("SET LOCAL statement_timeout = '#{timeout}'")
          yield
        end
      end
    end
  end
end
