class Dossiers::ExportComponent < ApplicationComponent
  def initialize(procedure:, exports:, statut: nil, count: nil, export_url: nil)
    @procedure = procedure
    @exports = exports
    @statut = statut
    @count = count
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
