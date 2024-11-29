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
    options = { class: "fr-link fr-icon-arrow-right-line fr-link--icon-right fr-ml-3w" }

    if has_next?
      tag.a(t('.next'), **options.merge(href: next_instructeur_dossier_path(dossier:, statut:)))
    else
      options[:class] = "#{options[:class]} fr-text-mention--grey"
      tag.span(t('.next'), **options)
    end
  end

  def link_previous
    options = { class: "fr-link fr-icon-arrow-left-line fr-link--icon-left" }

    if has_previous?
      tag.a(t('.previous'), **options.merge(href: previous_instructeur_dossier_path(dossier:, statut:)))
    else
      options[:class] = "#{options[:class]} fr-text-mention--grey"
      tag.span(t('.previous'), **options)
    end
  end

  def has_next? = @has_next ||= @cache.next_dossier_id(from_id: dossier.id).present?

  def has_previous? = @has_previous ||= @cache.previous_dossier_id(from_id: dossier.id).present?
end
