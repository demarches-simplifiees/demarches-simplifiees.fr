module Users
  class CommencerController < ApplicationController
    include QueryParamsStoreConcern

    layout 'procedure_context'

    before_action :retrieve_prefilled_dossier,        if: -> { params[:token].present? },                        only: :commencer
    before_action :set_prefilled_dossier_ownership,   if: -> { user_signed_in? && @prefilled_dossier&.orphan? }, only: :commencer
    before_action :check_prefilled_dossier_ownership, if: -> { user_signed_in? && @prefilled_dossier },          only: :commencer

    def commencer
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?

      store_query_params

      @revision = @procedure.published_revision
      render 'commencer/show'
    end

    def commencer_test
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || (@procedure.publiee? && !@procedure.draft_changed?)
      @revision = @procedure.draft_revision

      render 'commencer/show'
    end

    def dossier_vide_pdf
      @procedure = retrieve_procedure_with_closed
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?

      generate_empty_pdf(@procedure.published_revision)
    end

    def dossier_vide_pdf_test
      @procedure = retrieve_procedure_with_closed
      return procedure_not_found if @procedure.blank?

      generate_empty_pdf(@procedure.draft_revision)
    end

    def sign_in
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to new_user_session_path
    end

    def sign_up
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to new_user_registration_path
    end

    def france_connect
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to france_connect_particulier_path
    end

    def procedure_for_help
      retrieve_procedure
    end

    private

    def retrieve_procedure
      Procedure.publiees.or(Procedure.brouillons).find_by(path: params[:path])
    end

    def retrieve_procedure_with_closed
      Procedure.publiees.or(Procedure.brouillons).or(Procedure.closes).find_by(path: params[:path])
    end

    def retrieve_prefilled_dossier
      @prefilled_dossier = Dossier.state_brouillon.prefilled.find_by!(prefill_token: params[:token])
    end

    # The prefilled dossier is not owned yet, and the user is signed in: they become the new owner
    def set_prefilled_dossier_ownership
      @prefilled_dossier.update!(user: current_user)
    end

    # The prefilled dossier is owned by another user: raise an exception
    def check_prefilled_dossier_ownership
      raise ActiveRecord::RecordNotFound unless @prefilled_dossier.owned_by?(current_user)
    end

    def procedure_not_found
      procedure = Procedure.find_by(path: params[:path])

      if procedure&.replaced_by_procedure
        redirect_to commencer_path(path: procedure.replaced_by_procedure.path)
        return
      elsif procedure&.close?
        flash.alert = procedure.service.presence ?
                      t('errors.messages.procedure_archived.with_service_and_phone_email', service_name: procedure.service.nom, service_phone_number: procedure.service.telephone, service_email: procedure.service.email) :
                      t('errors.messages.procedure_archived.with_organisation_only', organisation_name: procedure.organisation)
      else
        flash.alert = t('errors.messages.procedure_not_found')
      end

      redirect_to root_path
    end

    def store_user_location!(procedure)
      store_location_for(:user, helpers.procedure_lien(procedure, token: params[:token]))
    end

    def generate_empty_pdf(revision)
      @dossier = revision.new_dossier
      data = render_to_string(template: 'dossiers/dossier_vide', formats: [:pdf])
      send_data(data, filename: "#{revision.procedure.libelle}.pdf")
    end
  end
end
