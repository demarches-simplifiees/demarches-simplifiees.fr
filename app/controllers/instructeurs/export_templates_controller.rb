module Instructeurs
  class ExportTemplatesController < InstructeurController
    before_action :set_procedure
    before_action :set_groupe_instructeur, only: [:create, :update]
    before_action :set_export_template, only: [:edit, :update, :destroy]
    before_action :set_groupe_instructeurs
    before_action :set_all_pj

    def new
      @export_template = ExportTemplate.new(kind: 'zip', groupe_instructeur: @groupe_instructeurs.first)
      @export_template.set_default_values
    end

    def create
      @export_template = @groupe_instructeur.export_templates.build(export_template_params)
      @export_template.assign_pj_names(pj_params)
      if @export_template.save
        redirect_to exports_instructeur_procedure_path(procedure: @procedure), notice: "Le modèle d'export #{@export_template.name} a bien été créé"
      else
        flash[:alert] = @export_template.errors.full_messages
        render :new
      end
    end

    def edit
    end

    def update
      @export_template.assign_attributes(export_template_params)
      @export_template.groupe_instructeur = @groupe_instructeur
      @export_template.assign_pj_names(pj_params)
      if @export_template.save
        redirect_to exports_instructeur_procedure_path(procedure: @procedure), notice: "Le modèle d'export #{@export_template.name} a bien été modifié"
      else
        flash[:alert] = @export_template.errors.full_messages
        render :edit
      end
    end

    def destroy
      if @export_template.destroy
        redirect_to exports_instructeur_procedure_path(procedure: @procedure), notice: "Le modèle d'export #{@export_template.name} a bien été supprimé"
      else
        redirect_to exports_instructeur_procedure_path(procedure: @procedure), alert: "Le modèle d'export #{@export_template.name} n'a pu être supprimé"
      end
    end

    def preview
      set_groupe_instructeur
      @export_template = @groupe_instructeur.export_templates.build(export_template_params)
      @export_template.assign_pj_names(pj_params)

      @sample_dossier = @procedure.dossier_for_preview(current_instructeur)

      render turbo_stream: turbo_stream.replace('preview', partial: 'preview', locals: { export_template: @export_template, procedure: @procedure, dossier: @sample_dossier })
    end

    private

    def export_template_params
      params.require(:export_template).permit(*export_params)
    end

    def set_procedure
      @procedure = current_instructeur.procedures.find params[:procedure_id]
      Sentry.configure_scope do |scope|
        scope.set_tags(procedure: @procedure.id)
      end
    end

    def set_export_template
      @export_template = current_instructeur.export_templates.find(params[:id])
    end

    def set_groupe_instructeur
      @groupe_instructeur = @procedure.groupe_instructeurs.find(params.require(:export_template)[:groupe_instructeur_id])
    end

    def set_groupe_instructeurs
      @groupe_instructeurs = current_instructeur.groupe_instructeurs.where(procedure: @procedure)
    end

    def set_all_pj
      @all_pj ||= @procedure.exportables_pieces_jointes
    end

    def export_params
      [:name, :kind, :tiptap_default_dossier_directory, :tiptap_pdf_name]
    end

    def pj_params
      @procedure = current_instructeur.procedures.find params[:procedure_id]
      pj_params = []
      @all_pj.each do |pj|
        pj_params << "tiptap_pj_#{pj.stable_id}".to_sym
      end
      params.require(:export_template).permit(*pj_params)
    end
  end
end
