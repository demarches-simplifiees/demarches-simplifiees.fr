# frozen_string_literal: true

module Administrateurs
  class ReferentielsController < AdministrateurController
    before_action :retrieve_procedure
    before_action :retrieve_type_de_champ
    before_action :retrieve_referentiel, except: [:new, :create]
    layout 'empty_layout'

    def new
      @referentiel = @type_de_champ.build_referentiel(referentiel_params)
    end

    def edit
    end

    def create
      referentiel = @type_de_champ.build_referentiel(referentiel_params)

      if referentiel.configured? && referentiel.update(referentiel_params)
        redirect_to mapping_type_de_champ_admin_procedure_referentiel_path(@procedure, @type_de_champ.stable_id, referentiel)
      else
        component = Referentiels::NewFormComponent.new(referentiel:, type_de_champ: @type_de_champ, procedure: @procedure)
        render turbo_stream: turbo_stream.replace(component.id, component)
      end
    end

    def update
      if @referentiel.update(referentiel_params)
        redirect_to mapping_type_de_champ_admin_procedure_referentiel_path(@procedure, @type_de_champ.stable_id, @referentiel)
      else
        render :edit
      end
    end

    def mapping_type_de_champ
      @service = ReferentielService.new(referentiel: @referentiel)
      if @service.test
        render
      else
        redirect_to edit_admin_procedure_referentiel_path(@procedure, @type_de_champ.stable_id)
      end
    end

    def update_mapping_type_de_champ
      flash = if @type_de_champ.update(type_de_champ_mapping_params)
        { notice: "ok" }
      else
        { alert: "ko" }
      end
      redirect_to prefill_and_visibility_admin_procedure_referentiel_path(@procedure, @type_de_champ.stable_id, @referentiel), flash:
    end

    def prefill_and_visibility
    end

    private

    def type_de_champ_mapping_params
      params.require(:type_de_champ)
        .permit(referentiel_mapping: [:jsonpath, :type, :prefill, :libelle])
    end

    def referentiel_params
      params.require(:referentiel)
        .permit(:type, :mode, :url, :hint, :test_data)
    rescue ActionController::ParameterMissing
      {}
    end

    def retrieve_type_de_champ
      @type_de_champ = @procedure.draft_revision.find_and_ensure_exclusive_use(params[:stable_id])
    end

    def retrieve_referentiel
      @referentiel = Referentiel.find(params[:id])
    end
  end
end
