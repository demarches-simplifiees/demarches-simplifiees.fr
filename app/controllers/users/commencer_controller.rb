module Users
  class CommencerController < ApplicationController
    layout 'procedure_context'

    def commencer
      @procedure = Procedure.publiees.find_by(path: params[:path])
      return procedure_not_found if @procedure.blank?

      render 'commencer/show'
    end

    def commencer_test
      @procedure = Procedure.brouillons.find_by(path: params[:path])
      return procedure_not_found if @procedure.blank?

      render 'commencer/show'
    end

    def sign_in
      @procedure = Procedure.find_by(path: params[:path])
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to new_user_session_path
    end

    def sign_up
      @procedure = Procedure.find_by(path: params[:path])
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to new_user_registration_path
    end

    def france_connect
      @procedure = Procedure.find_by(path: params[:path])
      return procedure_not_found if @procedure.blank?

      store_user_location!(@procedure)
      redirect_to france_connect_particulier_path
    end

    def procedure_for_help
      Procedure.publiees.find_by(path: params[:path]) || Procedure.brouillons.find_by(path: params[:path])
    end

    private

    def procedure_not_found
      procedure = Procedure.find_by(path: params[:path])

      if procedure&.archivee?
        flash.alert = t('errors.messages.procedure_archived')
      elsif procedure&.publiee?
        flash.alert = t('errors.messages.procedure_not_draft')
      else
        flash.alert = t('errors.messages.procedure_not_found')
      end

      return redirect_to root_path
    end

    def store_user_location!(procedure)
      store_location_for(:user, helpers.procedure_lien(procedure))
    end
  end
end
