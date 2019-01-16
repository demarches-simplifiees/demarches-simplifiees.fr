module ProcedureContextConcern
  extend ActiveSupport::Concern

  include Devise::Controllers::StoreLocation
  include Devise::StoreLocationExtension

  def restore_procedure_context
    if has_stored_procedure_path?
      @procedure = find_procedure_in_context

      if @procedure.blank?
        invalid_procedure_context
      end
    end
  end

  private

  def has_stored_procedure_path?
    get_stored_location_for(:user)&.start_with?('/commencer/')
  end

  def find_procedure_in_context
    uri = URI(get_stored_location_for(:user))
    path_components = uri.path.split('/')

    if uri.path.start_with?('/commencer/test/')
      Procedure.brouillon.find_by(path: path_components[3])
    elsif uri.path.start_with?('/commencer/')
      Procedure.publiee.find_by(path: path_components[2])
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
