class Dossiers::ExportLinkComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(procedure:, exports:, statut: nil, count: nil, class_btn: nil, export_url: nil)
    @procedure = procedure
    @exports = exports
    @statut = statut
    @count = count
    @class_btn = class_btn
    @export_url = export_url
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

  def refresh_button_options(export)
    {
      title: t(".refresh_old_export", export_format: ".#{export.format}"),
      class: "fr-btn  fr-btn--sm fr-icon-refresh-line fr-btn--icon-left fr-btn--tertiary fr-mt-1w"
    }
  end

  def ready_link_label(export)
    t(".everything_ready",
      export_format: ".#{export.format}")
  end

  def ready_link_label_extra_infos(export)
    t(".ready_link_label_extra_infos",
      export_time: helpers.time_ago_in_words(export.updated_at),
      export_tabs: export.statut.to_s)
  end

  def pending_label(export)
    t(".everything_pending_html",
      export_time: time_ago_in_words(export.created_at),
      export_format: ".#{export.format}")
  end

  def failed_label(export)
    t(".failed_label",
      export_format: ".#{export.format}")
  end

  def poll_controller_options(export)
    {
      controller: 'turbo-poll',
      turbo_poll_url_value: download_export_path(export_format: export.format, no_progress_notification: true),
      turbo_poll_interval_value: 6000,
      turbo_poll_max_checks_value: 10
    }
  end
end
