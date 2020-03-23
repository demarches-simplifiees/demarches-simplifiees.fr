module Users
  class CommencerController < ApplicationController
    layout 'procedure_context'

    def commencer
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?
      if !user_signed_in?
        store_user_location!(@procedure)
      end
      render 'commencer/show'
    end

    def commencer_test
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.publiee?
      if !user_signed_in?
        store_user_location!(@procedure)
      end
      render 'commencer/show'
    end

    def dossier_vide_pdf
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?

      generate_empty_pdf(@procedure)
    end

    def dossier_vide_pdf_test
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank? || @procedure.publiee?

      generate_empty_pdf(@procedure)
    end

    def sign_in
      @procedure = retrieve_procedure
      return procedure_not_found if @procedure.blank?
      store_user_location!(@procedure)

      redirect_to new_user_session_path
    end

    # Not needed anymore as the procedure is stored before when user is not logged
    # def sign_up
    #   @procedure = retrieve_procedure
    #   return procedure_not_found if @procedure.blank?
    #   store_user_location!(@procedure)
    #
    #   redirect_to new_user_registration_path
    # end
    #
    # def france_connect
    #   @procedure = retrieve_procedure
    #   return procedure_not_found if @procedure.blank?
    #   store_user_location!(@procedure)
    #
    #   redirect_to france_connect_particulier_path
    # end

    def procedure_for_help
      retrieve_procedure
    end

    private

    def retrieve_procedure
      Procedure.publiees.or(Procedure.brouillons).find_by(path: params[:path])
    end

    def procedure_not_found
      procedure = Procedure.find_by(path: params[:path])

      if procedure&.close?
        flash.alert = t('errors.messages.procedure_archived')
      else
        flash.alert = t('errors.messages.procedure_not_found')
      end

      redirect_to root_path
    end

    def store_user_location!(procedure)
      store_location_for(:user, helpers.procedure_lien(procedure))
    end

    def generate_empty_pdf(procedure)
      @dossier = procedure.new_dossier
      s = render_to_string(file: 'dossiers/dossier_vide', formats: [:pdf])
      send_data(s, :filename => "#{procedure.libelle}.pdf")
    end
  end
end
