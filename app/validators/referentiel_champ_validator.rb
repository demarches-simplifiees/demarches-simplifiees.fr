# frozen_string_literal: true

class ReferentielChampValidator < ActiveModel::Validator
  # case required, delegated to check_mandatory_and_visible_champs
  def validate(record)
    return if record.external_id.blank? # not filled by user
    return if record.data.present? # already fetched successfully

    if record.fetch_external_data_pending? # user filled the field, but background job is still running / pending
      record.errors.add(:value, :api_response_pending)
    elsif record.fetch_external_data_error? # user filled the field, but background job failed
      record.errors.add(:value, :api_response_error)
    else # this is unexpected
      Sentry.capture_message(
        "ReferentielChampValidator: unexpected state for champ #{record.id} (#{record.external_id})",
        extra: {
          value: record.value,
          data: record.data,
          value_json: record.value_json,
          fetch_external_data_exceptions: record.fetch_external_data_exceptions
        }
      )
      # record.errors.add(:value, :unexpected_state)
    end
  end
end
