# frozen_string_literal: true

module Gestionnaires
  class GroupeGestionnaireChildrenController < GestionnaireController
    before_action :retrieve_groupe_gestionnaire

    def index
    end

    def create
      if (@child = @groupe_gestionnaire.children.create!(name: params.require(:groupe_gestionnaire)[:name]))
        flash[:notice] = "Le groupe enfants a bien été créé"
      else
        flash[:alert] = @child.errors.full_messages
      end
    end
  end
end
