module Instructeurs
  class LexpolController < ApplicationController
    before_action :authenticate_instructeur!
    before_action :set_dossier_and_champ

    def create_dossier
      mapping = (@champ.type_de_champ.lexpol_mapping || "")
        .split("\n")
        .map { |pair| pair.split('=').map(&:strip) }
        .to_h

      variables = @dossier.champs.each_with_object({}) do |ch, hash|
        next unless ch.value.present? && ch.type_de_champ&.libelle.present?

        mapped_key = mapping[ch.type_de_champ.libelle] || ch.type_de_champ.libelle
        hash[mapped_key] = ch.value
      end

      nor = APILexpol.new.create_dossier(598706, variables)

      if nor.present?
        @champ.update!(value: nor)
        flash[:notice] = "Dossier Lexpol créé avec succès. Numéro NOR : #{nor}"
      else
        flash[:alert] = "Le numéro NOR n'a pas été trouvé dans la réponse de l'API."
      end
      redirect_to annotations_privees_instructeur_dossier_path(@dossier.procedure, @dossier)
    end

    def update_dossier
      mapping = (@champ.type_de_champ.lexpol_mapping || "")
        .split("\n")
        .map { |pair| pair.split('=').map(&:strip) }
        .to_h

      variables = @dossier.champs.each_with_object({}) do |ch, hash|
        next unless ch.value.present? && ch.type_de_champ&.libelle.present?

        mapped_key = mapping[ch.type_de_champ.libelle] || ch.type_de_champ.libelle
        hash[mapped_key] = ch.value
      end

      if @champ.lexpol_update_dossier(variables)
        flash[:notice] = "Dossier Lexpol mis à jour avec succès."
      else
        flash[:alert] = @champ.errors.full_messages.join(', ')
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
