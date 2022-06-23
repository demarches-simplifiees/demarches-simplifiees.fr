module Instructeurs
  class ExportsController < InstructeurController
    def index
      @can_download_dossiers = current_instructeur
        .dossiers
        .visible_by_administration
        .exists?(groupe_instructeur: groupe_instructeurs)
      export = Export.find_or_create_export(export_format, groupe_instructeurs, **export_options)

      if export.ready? && export.old? && force_export?
        export.destroy
        export = Export.find_or_create_export(export_format, groupe_instructeurs, **export_options)
      end

      if export.ready?
        respond_to do |format|
          format.turbo_stream do
            @procedure = procedure
            @statut = export_options[:statut]
            @dossiers_count = export.count
            assign_exports
            flash.notice = "L’export au format \"#{export_format}\" est prêt. Vous pouvez le <a href=\"#{export.file.service_url}\">télécharger</a>"
          end

          format.html do
            redirect_to export.file.service_url
          end
        end
      else
        respond_to do |format|
          notice_message = "Nous générons cet export. Veuillez revenir dans quelques minutes pour le télécharger."

          format.turbo_stream do
            @procedure = procedure
            @statut = export_options[:statut]
            @dossiers_count = export.count
            assign_exports
            if !params[:no_progress_notification]
              flash.notice = notice_message
            end
          end

          format.html do
            redirect_to instructeur_procedure_url(procedure), notice: notice_message
          end
        end
      end
    end

    private

    # + but common
    def groupe_instructeurs
      current_instructeur
        .groupe_instructeurs
        .where(procedure: procedure)
    end

    # -
    def export_format
      @export_format ||= params[:export_format]
    end

    def force_export?
      @force_export ||= params[:force_export].present?
    end

    def export_options
      @export_options ||= {
        time_span_type: params[:time_span_type],
        statut: params[:statut],
        procedure_presentation: params[:statut].present? ? procedure_presentation : nil
      }.compact
    end

    # DUPLICATE
    def procedure_id
      params[:procedure_id]
    end

    def procedure
      Procedure
        .find(procedure_id)
    end

    def assign_exports
      @exports = Export.find_for_groupe_instructeurs(groupe_instructeurs, procedure_presentation)
    end

    def procedure_presentation
      @procedure_presentation ||= get_procedure_presentation
    end

    def get_procedure_presentation
      procedure_presentation, errors = current_instructeur.procedure_presentation_and_errors_for_procedure_id(procedure_id)
      if errors.present?
        flash[:alert] = "Votre affichage a dû être réinitialisé en raison du problème suivant : " + errors.full_messages.join(', ')
      end
      procedure_presentation
    end
  end
end
