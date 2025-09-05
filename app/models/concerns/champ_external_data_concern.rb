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
    before_save :cleanup_if_empty

    # useful to serialize idle as nil
    # otherwise, all the champ are mark as dirty and saved on first dossier.save
    enum :external_state, {
      idle: nil, # initial state
      waiting_for_job: 'waiting_for_job',
      fetching: 'fetching',
      fetched: 'fetched',
      external_error: 'external_error'
    }

    aasm column: :external_state, enum: true do
      state :idle, initial: true
      state :waiting_for_job
      state :fetching
      state :fetched
      state :external_error

      event :fetch_later, after_commit: :fetch_external_data_later do
        transitions from: :idle, to: :waiting_for_job, guard: :ready_for_external_call?
      end

      # TODO: remove idle after first MEP
      event :fetch, after_commit: :fetch_and_handle_result do
        transitions from: [:idle, :waiting_for_job], to: :fetching
      end

      # TODO: remove idle after first MEP
      event :external_data_fetched do
        transitions from: [:idle, :fetching], to: :fetched
      end

      # TODO: remove idle after first MEP
      event :external_data_error do
        transitions from: [:idle, :fetching], to: :external_error
      end

      # TODO: remove idle after first MEP
      event :retry do
        transitions from: [:idle, :fetching], to: :waiting_for_job
      end

      # TODO: remove idle after first MEP
      event :reset_external_data, after: :after_reset_external_data do
        transitions from: [:waiting_for_job, :fetching, :fetched, :external_error], to: :idle
      end
    end

    def pending? = waiting_for_job? || fetching?

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

    def external_error_present?
      fetch_external_data_exceptions.present? && self.external_id.present?
    end

    def save_external_exception(exception, code)
      update_columns(fetch_external_data_exceptions: [ExternalDataException.new(reason: exception.inspect, code:)], data: nil, value_json: nil, value: nil)
    end

    def uses_external_data?
      false
    end

    private

    def should_ui_auto_refresh?
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

    def cleanup_if_empty
      if uses_external_data? && persisted? && external_identifier_changed?
        self.data = nil
      end
    end

    def handle_result(result)
      if result.is_a?(Dry::Monads::Result)
        case result
        in Success(data)
          update_external_data!(data:)
          external_data_fetched!
        in Failure(retryable: true, reason:, code:)
          save_external_exception(reason, code)
          retry!
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

    def after_reset_external_data
      update(data: nil, value_json: nil, fetch_external_data_exceptions: [])
    end
  end
end
