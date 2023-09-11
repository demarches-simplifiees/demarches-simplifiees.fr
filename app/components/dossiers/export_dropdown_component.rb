class Dossiers::ExportDropdownComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(procedure:, exports:, statut: nil, count: nil, class_btn: nil, export_url: nil)
    @procedure = procedure
    @exports = exports
    @statut = statut
    @count = count
    @class_btn = class_btn
    @export_url = export_url
  end

  def exports
    if @statut
      Export::FORMATS.filter(&method(:allowed_format?)).map do |item|
        export = @exports
          .fetch(item.fetch(:format))
          .fetch(:statut)
          .fetch(@statut, nil)
        item.merge(export: export)
      end
    else
      Export::FORMATS_WITH_TIME_SPAN.map do |item|
        export = @exports
          .fetch(item.fetch(:format))
          .fetch(:time_span_type)
          .fetch(item.fetch(:time_span_type), nil)
        item.merge(export: export)
      end
    end
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
