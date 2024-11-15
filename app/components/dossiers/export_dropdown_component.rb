# frozen_string_literal: true

class Dossiers::ExportDropdownComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(procedure:, export_templates: nil, statut: nil, count: nil, class_btn: nil, export_url: nil, show_export_template_tab: true)
    @procedure = procedure
    @export_templates = export_templates
    @statut = statut
    @count = count
    @class_btn = class_btn
    @export_url = export_url
    @show_export_template_tab = show_export_template_tab
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

  def download_export_path(export_format: nil, export_template_id: nil, no_progress_notification: nil)
    @export_url.call(@procedure,
      export_format:,
      export_template_id:,
      statut: @statut,
      no_progress_notification: no_progress_notification)
  end

  def export_templates
    @export_templates
  end
end
