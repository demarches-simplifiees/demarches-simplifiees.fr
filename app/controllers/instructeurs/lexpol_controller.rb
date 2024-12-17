module Instructeurs
  class LexpolController < ApplicationController
    before_action :authenticate_instructeur!
    before_action :set_dossier_and_champ

    def create_dossier
      if @champ.lexpol_create_dossier
        redirect_to annotations_instructeur_dossier_path(@dossier.procedure, @dossier), notice: 'Dossier Lexpol créé avec succès.'
      else
        redirect_to annotations_instructeur_dossier_path(@dossier.procedure, @dossier), alert: @champ.errors.full_messages.join(', ')
      end
    end

    def update_dossier
      if @champ.lexpol_update_dossier
        redirect_to annotations_instructeur_dossier_path(@dossier.procedure, @dossier), notice: 'Dossier Lexpol mis à jour avec succès.'
      else
        redirect_to annotations_instructeur_dossier_path(@dossier.procedure, @dossier), alert: @champ.errors.full_messages.join(', ')
      end
    end

    private

    def set_dossier_and_champ
      @dossier = Dossier.find(params[:dossier_id])
      @champ = @dossier.champs.find(params[:champ_id])
    end
  end
end
