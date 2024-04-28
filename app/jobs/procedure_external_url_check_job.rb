# frozen_string_literal: true

class ProcedureExternalURLCheckJob < ApplicationJob
  def perform(procedure)
    procedure.validate

    if procedure.lien_notice.present?
      error = procedure.errors.find { _1.attribute == :lien_notice }

      procedure.lien_notice_error = check_for_error(error, procedure.lien_notice)
      procedure.save!(validate: false) # others errors may prevent save if validate
    end

    if procedure.lien_dpo.present? && !procedure.lien_dpo_email?
      error = procedure.errors.find { _1.attribute == :lien_dpo }

      procedure.lien_dpo_error = check_for_error(error, procedure.lien_dpo)
      procedure.save!(validate: false)
    end
  end

  private

  def check_for_error(error, url)
    return error.message if error.present?

    response = Typhoeus.get(url, followlocation: true)

    return if response.success?

    "#{response.code} #{response.return_message}"
  end
end
