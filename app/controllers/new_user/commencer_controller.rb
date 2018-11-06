module NewUser
  class CommencerController < ApplicationController
    def commencer_test
      procedure = Procedure.brouillons.find_by(path: params[:path])

      if procedure.present?
        redirect_to new_dossier_path(procedure_id: procedure.id, brouillon: true)
      else
        flash.alert = "La démarche est inconnue."
        redirect_to root_path
      end
    end

    def commencer
      procedure = Procedure.publiees.find_by(path: params[:path])

      if procedure.present?
        redirect_to new_dossier_path(procedure_id: procedure.id)
      else
        flash.alert = "La démarche est inconnue, ou la création de nouveaux dossiers pour cette démarche est terminée."
        redirect_to root_path
      end
    end
  end
end
