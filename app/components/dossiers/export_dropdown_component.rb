class Dossiers::ExportDropdownComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(procedure:, statut: nil, count: nil, class_btn: nil, export_url: nil)
    @procedure = procedure
    @statut = statut
    @count = count
    @class_btn = class_btn
    @export_url = export_url
  end

  def formats
    if @statut
      Export::FORMATS.filter(&method(:allowed_format?))
    else
      Export::FORMATS_WITH_TIME_SPAN
    end.map { _1[:format] }
  end

  def allowed_format?(item)
    item.fetch(:format) != :json || @procedure.active_revision.carte?
  end

  def download_export_path(export_format:, force_export: false, no_progress_notification: nil)
    @export_url.call(@procedure,
      export_format: export_format,
      statut: @statut,
      force_export: force_export,
      no_progress_notification: no_progress_notification)
  end
end
