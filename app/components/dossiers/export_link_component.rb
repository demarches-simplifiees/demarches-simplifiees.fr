class Dossiers::ExportLinkComponent < ApplicationComponent
  include ApplicationHelper
  include TabsHelper

  def initialize(procedure:, exports:, statut: nil, count: nil, class_btn: nil, export_url: nil)
    @procedure = procedure
    @exports = exports
    @statut = statut
    @count = count
    @class_btn = class_btn
    @export_url = export_url
  end

  def download_export_path(export_format:, statut:, no_progress_notification: nil)
    @export_url.call(@procedure,
      export_format: export_format,
      statut: statut,
      no_progress_notification: no_progress_notification)
  end

  def time_info(export)
    if export.available?
      t(".ready_link_label_time_info", export_time: helpers.time_ago_in_words(export.updated_at))
    else
      t(".not_ready_link_label_time_info", export_time: helpers.time_ago_in_words(export.created_at))
    end
  end

  def export_title(export)
    if export.procedure_presentation_id.nil?
      t(".export_title_everything", export_format: export.format)
    elsif export.tous?
      t(".export_title", export_format: export.format, count: export.count)
    else
      t(".export_title_with_tab", export_tabs: human_export_status(export), export_format: export.format, count: export.count)
    end
  end

  def human_export_status(export)
    key = tab_i18n_key_from_status(export.statut)

    t(key, count: export.count) || export.statut
  end

  def badge(export)
    if export.available?
      content_tag(:span, t(".success_label"), { class: "fr-badge fr-badge--success fr-text-right" })
    elsif export.failed?
      content_tag(:span, t(".failed_label"), { class: "fr-badge fr-badge--warning fr-text-right" })
    else
      content_tag(:span, t(".pending_label"), { class: "fr-badge fr-badge--info fr-text-right" })
    end
  end

  def export_button(export)
    if export.available?
      render Dsfr::DownloadComponent.new(attachment: export.file, name: t('.download_export'))
    elsif export.pending?
      content_tag(:a, t('.refresh_page'), { href: "", class: 'fr-btn fr-btn--sm fr-btn--tertiary' })
    end
  end

  def refresh_button_options(export)
    {
      title: t(".refresh_old_export"),
      "aria-label" =>  t(".refresh_old_export"),
      class: "fr-btn fr-btn--sm fr-icon-refresh-line fr-btn--tertiary fr-btn--icon-left"
    }
  end
end
