module Instructeurs
  class ExportTemplatesController < InstructeurController
    def new
      assign_procedure_and_groupe_instructeur
      @export_template = ExportTemplate.new(kind: 'zip', groupe_instructeur: @groupe_instructeur)
      @export_template.set_default_values
    end

    def create
      assign_procedure_and_groupe_instructeur
      @export_template = current_instructeur.export_templates.build(export_template_params)
      @export_template.groupe_instructeur = @groupe_instructeur
      @export_template.assign_pj_names(pj_params)
      if @export_template.save
        redirect_to instructeur_procedure_path(@procedure), notice: "Le modèle d'export a bien été créé"
      else
        flash[:alert] = @export_template.errors.full_messages
        render :new
      end
    end

    def edit
      assign_procedure_and_groupe_instructeur
      @export_template = current_instructeur.export_templates.find(params[:id])
      render :edit
    end

    def update
      assign_procedure_and_groupe_instructeur
      @export_template = current_instructeur.export_templates.find(params[:id])
      @export_template.assign_attributes(export_template_params)
      @export_template.assign_pj_names(pj_params)
      if @export_template.save
        redirect_to instructeur_procedure_path(@procedure), notice: "Le modèle d'export a bien été modifié"
      else
        flash[:alert] = @export_template.errors.full_messages
        render :edit
      end
    end

    private

    def export_template_params
      params.require(:export_template).permit(*export_params)
    end

    def assign_procedure_and_groupe_instructeur
      @procedure = current_instructeur.procedures.find params[:procedure_id]
      @groupe_instructeur = current_instructeur.groupe_instructeurs.find params[:groupe_id]
    end

    def export_params
      [:name, :kind, :tiptap_default_dossier_directory, :tiptap_pdf_name]
    end

    def pj_params
      @procedure = current_instructeur.procedures.find params[:procedure_id]
      pj_params = []
      @procedure.all_pj.each do |pj|
        pj_params << "tiptap_pj_#{pj.stable_id}".to_sym
      end
      params.require(:export_template).permit(*pj_params)
    end
  end
end
