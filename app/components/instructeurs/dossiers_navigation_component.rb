# frozen_string_literal: true

class Instructeurs::DossiersNavigationComponent < ApplicationComponent
  attr_reader :dossier, :statut

  def initialize(dossier:, procedure_presentation:, statut:)
    @dossier = dossier
    @cache = Cache::ProcedureDossierPagination.new(procedure_presentation: procedure_presentation, statut:)
    @statut = statut
  end

  def back_url_options
    options = { statut: }
    options = options.merge(page: @cache.incoming_page) if @cache.incoming_page
    options
  end

  def link_next
    if has_next?
      html_tag = :a
      options = { class: "fr-link no-wrap fr-text--sm fr-ml-3w fr-icon-arrow-right-line fr-link--icon-right", href: next_instructeur_dossier_path(dossier:, statut:) }
    else
      html_tag = :span
      options = { class: "fr-link no-wrap fr-text--sm fr-ml-3w fr-text-mention--grey" }
    end

    tag.send(html_tag, t('.next').html_safe, **options)
  end

  def link_previous
    if has_previous?
      html_tag = :a
      options = { class: "fr-link no-wrap fr-text--sm fr-icon-arrow-left-line fr-link--icon-left", href: previous_instructeur_dossier_path(dossier:, statut:) }
    else
      html_tag = :span
      options = { class: "fr-link no-wrap fr-text--sm fr-text-mention--grey" }
    end

    tag.send(html_tag, t('.previous'), **options)
  end

  def has_next? = @has_next ||= @cache.next_dossier_id(from_id: dossier.id).present?

  def has_previous? = @has_previous ||= @cache.previous_dossier_id(from_id: dossier.id).present?
end
