# frozen_string_literal: true

module Instructeurs
  class RdvsController < InstructeurController
    before_action :set_dossier

    def create
      @rdv = RdvService.new.create_rdv(dossier: @dossier)
    end

    private

    def set_dossier
      @dossier = current_instructeur.dossiers.find(params[:dossier_id])
    end
  end
end
