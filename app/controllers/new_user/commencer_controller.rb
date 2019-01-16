module NewUser
  class CommencerController < ApplicationController
    layout 'procedure_context'

    def commencer
      @procedure = Procedure.publiees.find_by(path: params[:path])

      if @procedure.blank?
        flash.alert = "La démarche est inconnue, ou la création de nouveaux dossiers pour cette démarche est terminée."
        return redirect_to root_path
      end

      render 'commencer/show'
    end

    def commencer_test
      @procedure = Procedure.brouillons.find_by(path: params[:path])

      if @procedure.blank?
        flash.alert = "La démarche est inconnue, ou cette démarche n’est maintenant plus en test."
        return redirect_to root_path
      end

      render 'commencer/show'
    end

    def sign_in
      store_user_location!
      redirect_to new_user_session_path
    end

    def sign_up
      store_user_location!
      redirect_to new_user_registration_path
    end

    private

    def store_user_location!
      procedure = Procedure.find_by(path: params[:path])
      store_location_for(:user, commencer_path(path: procedure.path))
    end
  end
end
