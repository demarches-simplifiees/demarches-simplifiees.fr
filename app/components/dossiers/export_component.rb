class Dossiers::ExportComponent < ApplicationComponent
  def initialize(procedure:, exports:, statut: nil, count: nil)
    @procedure = procedure
    @exports = exports
    @statut = statut
    @count = count
  end

  def exports
    helpers.exports_list(@exports, @statut)
  end

  def download_export_path(export_format:, force_export: false, no_progress_notification: nil)
    export_instructeur_procedure_path(@procedure,
      export_format: export_format,
      statut: @statut,
      force_export: force_export,
      no_progress_notification: no_progress_notification)
  end

  def refresh_button_options(export)
    {
      title: t(".everything_short", export_format: ".#{export.format}"),
      class: "button small",
      style: "padding-right: 2px"
    }
  end

  def ready_link_label(export)
    t(".everything_ready_html",
      export_time: helpers.time_ago_in_words(export.updated_at),
      export_format: ".#{export.format}")
  end

  def pending_label(export)
    t(".everything_pending_html",
      export_time: time_ago_in_words(export.created_at),
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
