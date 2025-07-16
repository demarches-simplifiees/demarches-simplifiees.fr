# frozen_string_literal: true

module ChampExternalDataConcern
  extend ActiveSupport::Concern

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

    def fetch_external_data_pending?
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

    def update_with_external_data!(data:)
      update!(data: data, fetch_external_data_exceptions: [])
    end

    def log_fetch_external_data_exception(exception, code)
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
  end
end
