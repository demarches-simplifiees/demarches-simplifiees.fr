# frozen_string_literal: true

class ReferentielChampValidator < ActiveModel::Validator
  # case required, delegated to check_mandatory_and_visible_champs
  def validate(record)
    return if record.external_id.blank? # not filled by user
    return if record.data.present? # already fetched successfully

    if record.waiting_for_external_data? # user filled the field, but background job is still running / pending
      record.errors.add(:value, :api_response_pending)
    elsif record.external_error_present? # user filled the field, but background job failed
      record.errors.add(:value, error_key_for_api_response_code(record))
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
    end
  end

  def error_key_for_api_response_code(record)
    http_status = record.fetch_external_data_exceptions.first.code
    error_key = :"code_#{http_status}"

    if http_status && translation_exists_for?(error_key, record)
      error_key
    else
      :api_response_error
    end
  end

  private

  def translation_exists_for?(error_key, record)
    model_key = record.class.model_name.i18n_key

    I18n.exists?("activerecord.errors.models.#{model_key}.attributes.value.#{error_key}") ||
      I18n.exists?("activerecord.errors.messages.#{error_key}")
  end
end
