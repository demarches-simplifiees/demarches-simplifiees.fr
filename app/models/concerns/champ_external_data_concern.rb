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
    attribute :fetch_external_data_exceptions, :external_data_exception, array: true
    before_save :cleanup_if_empty
    after_update_commit :fetch_external_data_later

    def uses_external_data?
      false
    end

    def should_ui_auto_refresh?
      false
    end

    def ready_for_external_call?
      external_id.present?
    end

    def external_data_present?
      data.present?
    end

    def external_error_present?
      fetch_external_data_exceptions.present? && self.external_id.present?
    end

    def waiting_for_external_data?
      uses_external_data? &&
        should_ui_auto_refresh? &&
        ready_for_external_call? &&
        (!external_data_present? && !external_error_present?)
    end

    def external_data_fetched?
      uses_external_data? &&
        should_ui_auto_refresh? &&
        ready_for_external_call? &&
        (external_data_present? || external_error_present?)
    end

    def fetch_external_data
      raise NotImplemented.new(:fetch_external_data)
    end

    def update_external_data!(data:)
      update!(data: data, fetch_external_data_exceptions: [])
    end

    def save_external_exception(exception, code)
      update_columns(fetch_external_data_exceptions: [ExternalDataException.new(reason: exception.inspect, code:)], data: nil, value_json: nil, value: nil)
    end

    def cleanup_if_empty
      if uses_external_data? && persisted? && external_id_changed?
        self.data = nil
      end
    end

    def fetch_external_data_later
      if uses_external_data? && external_id.present? && data.nil?
        update_column(:fetch_external_data_exceptions, [])
        ChampFetchExternalDataJob.perform_later(self, external_id)
      end
    end

    def fetch_and_handle_result
      result = fetch_external_data
      handle_result(result)
    end

    private

    def handle_result(result)
      if result.is_a?(Dry::Monads::Result)
        case result
        in Success(data)
          update_external_data!(data:)
        in Failure(retryable: true, reason:, code:)
          save_external_exception(reason, code)
          raise reason
        in Failure(retryable: false, reason:, code:)
          save_external_exception(reason, code)
          Sentry.capture_exception(reason)
        end
      elsif result.present?
        update_external_data!(data: result)
      end
    end
  end
end
