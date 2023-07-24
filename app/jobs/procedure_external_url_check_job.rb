class ProcedureExternalURLCheckJob < ApplicationJob
  def perform(procedure)
    procedure.validate

    if procedure.lien_notice.present?
      error = procedure.errors.find { _1.attribute == :lien_notice }
      if error.present?
        procedure.update!(lien_notice_error: error.message)
      else
        response = Typhoeus.get(procedure.lien_notice, followlocation: true)
        if response.success?
          procedure.update!(lien_notice_error: nil)
        else
          procedure.update!(lien_notice_error: "#{response.code} #{response.return_message}")
        end
      end
    end

    if procedure.lien_dpo.present? && !procedure.lien_dpo_email?
      error = procedure.errors.find { _1.attribute == :lien_dpo }
      if error.present?
        procedure.update!(lien_dpo_error: error.message)
      else
        response = Typhoeus.get(procedure.lien_dpo, followlocation: true)
        if response.success?
          procedure.update!(lien_dpo_error: nil)
        else
          procedure.update!(lien_dpo_error: "#{response.code} #{response.return_message}")
        end
      end
    end
  end
end
