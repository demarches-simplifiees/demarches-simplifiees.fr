# frozen_string_literal: true

module ProcedureContextConcern
  extend ActiveSupport::Concern

  include Devise::Controllers::StoreLocation
  include Devise::StoreLocationExtension

  def restore_procedure_context
    return unless has_stored_procedure_path?

    @procedure = find_procedure_in_context

    if @procedure.blank?
      invalid_procedure_context
    else
      @prefill_token = find_prefill_token_in_context
    end
  end

  private

  def has_stored_procedure_path?
    get_stored_location_for(:user)&.start_with?('/commencer/')
  end

  def find_procedure_in_context
    uri = URI(get_stored_location_for(:user))
    path_components = uri.path.split('/')

    Procedure.publiees_ou_brouillons.find_with_path(path_components[2]).first
  end

  def find_prefill_token_in_context
    uri = URI(get_stored_location_for(:user))
    CGI.parse(uri.query).dig("prefill_token")&.first if uri.query
  end

  def invalid_procedure_context
    clear_stored_location_for(:user)
    flash.alert = t('errors.messages.procedure_not_found')
    redirect_to root_path
  end
end
