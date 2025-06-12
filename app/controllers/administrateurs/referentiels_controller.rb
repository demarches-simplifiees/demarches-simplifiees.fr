# frozen_string_literal: true

module Administrateurs
  class ReferentielsController < AdministrateurController
    before_action :retrieve_procedure
    before_action :retrieve_type_de_champ
    before_action :retrieve_referentiel, except: [:new, :create]
    layout 'empty_layout'

    def new
      @referentiel = @type_de_champ.build_referentiel(build_or_clone_by_id_params)
    end

    def edit
      render :new
    end

    def create
      handle_referentiel_save(@type_de_champ.build_referentiel(referentiel_params))
    end

    def update
      @referentiel.assign_attributes(referentiel_params)
      handle_referentiel_save(@referentiel)
    end

    def mapping_type_de_champ
      @service = ReferentielService.new(referentiel: @referentiel)
      @service.validate_referentiel
    end

    def update_mapping_type_de_champ
      if @type_de_champ.update(type_de_champ_mapping_params)
        redirect_to prefill_and_display_admin_procedure_referentiel_path(@procedure, @type_de_champ.stable_id, @referentiel), flash: { notice: "La configuration du mapping a bien été enregistrée" }
      else
        redirect_to mapping_type_de_champ_admin_procedure_referentiel_path(@procedure, @type_de_champ.stable_id, @referentiel), flash: { alert: "Une erreur est survenue" }
      end
    end

    def prefill_and_display
      render :prefill_and_display
    end

    private

    def handle_referentiel_save(referentiel)
      if referentiel.configured? && referentiel.save && params[:commit].present?
        redirect_to mapping_type_de_champ_admin_procedure_referentiel_path(@procedure, @type_de_champ.stable_id, referentiel)
      else
        referentiel.validate
        component = Referentiels::NewFormComponent.new(referentiel:, type_de_champ: @type_de_champ, procedure: @procedure)
        render turbo_stream: turbo_stream.replace(component.id, component)
      end
    end

    def type_de_champ_mapping_params
      params.require(:type_de_champ)
        .permit(referentiel_mapping: {})
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

    def build_or_clone_by_id_params
      if params[:referentiel_id]
        Referentiel.find(params[:referentiel_id]).attributes.slice(*%w[url test_data hint mode type])
      else
        params = referentiel_params.to_h
        params = params.merge(type: Referentiels::APIReferentiel) if !Referentiels::APIReferentiel.csv_available?
        params = params.merge(mode: Referentiels::APIReferentiel.modes.fetch(:exact_match)) if !Referentiels::APIReferentiel.autocomplete_available?
        params
      end
    end
  end
end
