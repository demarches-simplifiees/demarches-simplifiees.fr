# frozen_string_literal: true

module Instructeurs
  class ExportTemplatesController < InstructeurController
    before_action :set_procedure_and_groupe_instructeurs
    before_action :set_export_template, only: [:edit, :update, :destroy]
    before_action :ensure_legitimate_groupe_instructeur, only: [:create, :update]

    def new
      kind = params[:kind] == 'zip' ? 'zip' : 'xlsx'

      @export_template = ExportTemplate.default(
        groupe_instructeur: @groupe_instructeurs.first,
        kind:
      )
    end

    def create
      @export_template = ExportTemplate.new(export_template_params)
      assign_columns

      if @export_template.save
        redirect_to [:exports, :instructeur, @procedure], notice: "Le modèle d'export #{@export_template.name} a bien été créé"
      else
        flash[:alert] = @export_template.errors.full_messages
        render :new
      end
    end

    def edit
    end

    def update
      @export_template.assign_attributes(export_template_params)
      assign_columns

      if @export_template.save
        redirect_to [:exports, :instructeur, @procedure], notice: "Le modèle d'export #{@export_template.name} a bien été modifié"
      else
        flash[:alert] = @export_template.errors.full_messages
        render :edit
      end
    end

    def destroy
      if @export_template.destroy
        redirect_to [:exports, :instructeur, @procedure], notice: "Le modèle d'export #{@export_template.name} a bien été supprimé"
      else
        redirect_to [:exports, :instructeur, @procedure], alert: "Le modèle d'export #{@export_template.name} n'a pu être supprimé"
      end
    end

    def preview
      export_template = ExportTemplate.new(export_template_params)

      render turbo_stream: turbo_stream.replace('preview', partial: 'preview', locals: { export_template: })
    end

    private

    def assign_columns
      columns = params.require(:export_template)[:columns]
      @export_template.columns = columns.map { JSON.parse(_1).symbolize_keys } if columns
    end

    def export_template_params
      params.require(:export_template)
        .permit(:name, :kind, :groupe_instructeur_id, dossier_folder: [:enabled, :template], export_pdf: [:enabled, :template], pjs: [:stable_id, :enabled, :template])
    end

    def set_procedure_and_groupe_instructeurs
      @procedure = current_instructeur.procedures.find(params[:procedure_id])
      @groupe_instructeurs = current_instructeur.groupe_instructeurs.where(procedure: @procedure)

      Sentry.configure_scope { |scope| scope.set_tags(procedure: @procedure.id) }
    end

    def set_export_template
      @export_template = current_instructeur.export_templates.find(params[:id])
    end

    def ensure_legitimate_groupe_instructeur
      return if export_template_params[:groupe_instructeur_id].in?(@groupe_instructeurs.map { _1.id.to_s })

      redirect_to [:exports, :instructeur, @procedure], alert: 'Vous n’avez pas le droit de créer un modèle d’export pour ce groupe'
    end
  end
end
