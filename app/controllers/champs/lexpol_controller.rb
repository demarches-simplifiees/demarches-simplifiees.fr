module Champs
  class LexpolController < Champs::ChampController

    def upsert
      service = LexpolService.new(champ: @champ, dossier: @champ.dossier)

      force_create = params[:force_create].present?
      nor = service.upsert_dossier(force_create: force_create)
      if nor.present?
        msg = @champ.value.blank? ? "Dossier Lexpol créé avec succès" :
                                    "Dossier Lexpol mis à jour avec succès"
        flash[:notice] = msg
      else
        flash[:alert] = "Impossible de #{@champ.value.blank? ? "créer" : "mettre à jour"} le dossier Lexpol."
      end

      redirect_back fallback_location: root_path
    end
  end
end
