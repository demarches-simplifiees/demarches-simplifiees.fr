module ProcedureContextConcern
  extend ActiveSupport::Concern

  include Devise::Controllers::StoreLocation
  include Devise::StoreLocationExtension

  def restore_procedure_context
    if stored_procedure_id.present?
      @procedure = Procedure.publiees.find_by(id: stored_procedure_id)

      if @procedure.blank?
        invalid_procedure_context
      end
    end
  end

  private

  def stored_procedure_id
    stored_location = get_stored_location_for(:user)

    if stored_location.present? && stored_location.include?('procedure_id=')
      stored_location.split('procedure_id=').second
    else
      nil
    end
  end

  def invalid_procedure_context
    clear_stored_location_for(:user)
    flash.alert = t('errors.messages.procedure_not_found')
    redirect_to root_path
  end
end
