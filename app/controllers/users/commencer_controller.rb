module Users
  class CommencerController < ApplicationController
    layout 'procedure_context'

    def commencer
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?

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
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?

      generate_empty_pdf(@procedure.published_revision)
    end

    def dossier_vide_pdf_test
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || (@procedure.publiee? && !@procedure.draft_changed?)

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
      store_location_for(:user, helpers.procedure_lien(procedure))
    end

    def generate_empty_pdf(revision)
      @dossier = revision.new_dossier
      data = render_to_string(template: 'dossiers/dossier_vide', formats: [:pdf])
      send_data(data, filename: "#{revision.procedure.libelle}.pdf")
    end
  end
end
