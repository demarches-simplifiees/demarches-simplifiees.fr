module Instructeurs
  class LexpolController < ApplicationController
    before_action :authenticate_instructeur!
    before_action :set_dossier_and_champ

    def upsert
      service = LexpolService.new(champ: @champ, dossier: @dossier)

      force_create = params[:force_create].present?
      nor = service.upsert_dossier(force_create: force_create)
      if nor.present?
        msg = @champ.value.blank? ? "Dossier Lexpol créé avec succès. NOR : #{nor}" :
                                    "Dossier Lexpol mis à jour avec succès. NOR : #{nor}"
        flash[:notice] = msg
      else
        flash[:alert] = "Impossible de #{@champ.value.blank? ? "créer" : "mettre à jour"} le dossier Lexpol."
      end

      redirect_to annotations_privees_instructeur_dossier_path(@dossier.procedure, @dossier)
    end

    private

    def set_dossier_and_champ
      @dossier = Dossier.find(params[:dossier_id])
      @champ   = @dossier.champs.find(params[:champ_id])
    end
  end
end
