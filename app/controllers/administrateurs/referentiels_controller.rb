# frozen_string_literal: true

module Administrateurs
  class ReferentielsController < AdministrateurController
    before_action :retrieve_procedure

    def new
      @procedure = draft.procedure
      @type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])
      @referentiel = @type_de_champ.build_referentiel(referentiel_params)

      render layout: "empty_layout"
    end

    def create
      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])
      referentiel = type_de_champ.referentiel || type_de_champ.build_referentiel(referentiel_params)

      if referentiel.configured? && referentiel.update(referentiel_params)
        redirect_to root_path # mapping_datasource_admin_procedure_type_de_champ_path(draft.procedure, type_de_champ.stable_id)
      else
        component = Referentiels::NewFormComponent.new(referentiel:, type_de_champ:, procedure: draft.procedure)
        render turbo_stream: turbo_stream.replace(component.id, component)
      end
    end

    def show
      @procedure = draft.procedure
      @type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])

      render layout: "empty_layout"
    end

    private

    def referentiel_params
      params.require(:referentiel)
        .permit(:type, :mode, :url, :hint, :test_data)
    rescue ActionController::ParameterMissing
      {}
    end

    def draft
      @procedure.draft_revision
    end
  end
end
