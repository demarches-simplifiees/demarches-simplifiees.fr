# frozen_string_literal: true

class Dossiers::ExportDropdownComponent < ApplicationComponent
  include ApplicationHelper

  attr_reader :wrapper
  attr_reader :export_templates

  def initialize(procedure:, export_templates: nil, statut: nil, count: nil, archived_count: 0, class_btn: nil, export_url: nil, show_export_template_tab: true, wrapper: :div)
    @procedure = procedure
    @export_templates = export_templates
    @statut = statut
    @count = count
    @archived_count = archived_count
    @class_btn = class_btn
    @export_url = export_url
    @show_export_template_tab = show_export_template_tab
    @wrapper = wrapper
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

  def can_include_archived?
    @statut == 'tous' && @archived_count > 0
  end

  def include_archived_title
    if @archived_count > 1
      "<span>Inclure les <strong>#{@archived_count} dossiers « à archiver »</strong></span>"
    else
      "<span>Inclure le <strong>dossier « à archiver »</strong></span>"
    end
  end

  def download_export_path(export_format: nil, export_template_id: nil, no_progress_notification: nil)
    @export_url.call(@procedure,
      export_format:,
      export_template_id:,
      statut: @statut,
      no_progress_notification: no_progress_notification)
  end
end
