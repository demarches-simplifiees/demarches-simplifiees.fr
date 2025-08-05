# frozen_string_literal: true

module ChampExternalDataConcern
  extend ActiveSupport::Concern

  include Dry::Monads[:result]

  # A champ is updated
  # before_save cleanup_if_empty : back to initial state if external_id
  # after_update_commit fetch_external_data_later : start ChampFetchExternalDataJob
  # the job call fetch_and_handle_result which return data or exception
  # if data, the job call update_external_data!
  # if exception, the job call save_external_exception

  included do
    include AASM

    attribute :fetch_external_data_exceptions, :external_data_exception, array: true

    aasm column: :external_state do
      state :idle, initial: true
      state :fetching
      state :fetched
      state :external_error

      event :fetch, after_commit: :fetch_external_data_later do
        transitions from: :idle, to: :fetching, guard: :ready_for_external_call?
      end

      event :external_data_fetched do
        transitions from: :fetching, to: :fetched
      end

      event :external_data_error do
        transitions from: :fetching, to: :external_error
      end

      event :reset_external_data, after: :after_reset_external_data do
        transitions from: [:fetching, :fetched, :external_error], to: :idle
      end
    end

    def fetch_external_data_later
      if uses_external_data? && ready_for_external_call? && data.nil?
        ChampFetchExternalDataJob.perform_later(self, external_id)
      end
    end

    # should not be overridden
    def fetch_and_handle_result
      result = fetch_external_data
      handle_result(result)
    end

    # should not be overridden
    def save_external_exception(exception, code)
      update_columns(fetch_external_data_exceptions: [ExternalDataException.new(reason: exception.inspect, code:)], data: nil, value_json: nil, value: nil)
    end

    def uses_external_data?
      false
    end

    # should not be overridden
    def should_ui_auto_refresh?
      can_ui_auto_refresh? && fetching?
    end

    private

    def can_ui_auto_refresh?
      false
    end

    def external_identifier_changed?
      external_id_changed?
    end

    def ready_for_external_call?
      external_id.present?
    end

    def external_data_present?
      data.present?
    end

    def fetch_external_data
      raise NotImplemented.new(:fetch_external_data)
    end

    def update_external_data!(data:)
      update!(data: data, fetch_external_data_exceptions: [])
    end

    # should not be overridden
    def after_reset_external_data
      update(data: nil, value_json: nil, fetch_external_data_exceptions: [])
    end

    # should not be overridden
    def handle_result(result)
      if result.is_a?(Dry::Monads::Result)
        case result
        in Success(data)
          update_external_data!(data:)
          external_data_fetched!
        in Failure(retryable: true, reason:, code:)
          save_external_exception(reason, code)
          raise reason
        in Failure(retryable: false, reason:, code:)
          save_external_exception(reason, code)
          Sentry.capture_exception(reason)
          external_data_error!
        end
      elsif result.present?
        update_external_data!(data: result)
        external_data_fetched!
      end
    end
  end
end
