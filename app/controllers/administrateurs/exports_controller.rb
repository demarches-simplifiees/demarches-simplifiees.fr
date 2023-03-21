module Administrateurs
  class ExportsController < AdministrateurController
    before_action :retrieve_procedure
    before_action :ensure_not_super_admin!

    def download
      export = Export.find_or_create_export(export_format, all_groupe_instructeurs, force: force_export?, **export_options)
      @dossiers_count = export.count
      assign_exports

      if export.available?
        respond_to do |format|
          format.turbo_stream do
            flash.notice = export.flash_message
          end

          format.html do
            redirect_to export.file.service_url
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            if !params[:no_progress_notification]
              flash.notice = export.flash_message
            end
          end
          format.html do
            redirect_to admin_procedure_archives_url(@procedure), notice: export.flash_message
          end
        end
      end
    end

    private

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
        procedure_presentation: nil
      }.compact
    end

    def all_groupe_instructeurs
      @procedure.groupe_instructeurs
    end

    def assign_exports
      @exports = Export.find_for_groupe_instructeurs(all_groupe_instructeurs.map(&:id), nil)
    end
  end
end
