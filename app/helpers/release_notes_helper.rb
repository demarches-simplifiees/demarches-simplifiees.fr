# frozen_string_literal: true

module ReleaseNotesHelper
  def announce_category_badge(category)
    color_class = color_by_role(category)

    content_tag(:span, ReleaseNote.human_attribute_name("categories.#{category}"), class: "fr-badge #{color_class}")
  end

  def color_by_role(role)
    case role.to_sym
    when :administrateur
      'fr-badge--blue-cumulus'
    when :instructeur
      'fr-badge--yellow-tournesol'
    when :expert
      'fr-badge--purple-glycine'
    when :usager
      'fr-badge--green-emeraude'
    when :api
      'fr-badge--pink-macaron'
    end
  end

  def infer_default_announce_categories
    if administrateur_signed_in?
      ReleaseNote.default_categories_for_role(:administrateur, current_administrateur)
    elsif instructeur_signed_in?
      ReleaseNote.default_categories_for_role(:instructeur, current_instructeur)
    elsif expert_signed_in?
      ReleaseNote.default_categories_for_role(:expert, current_expert)
    else
      ReleaseNote.default_categories_for_role(:usager)
    end
  end

  def render_release_note_content(content)
    ActionText::ContentHelper.allowed_tags = sanitizer_allowed_tags + %w[a]
    ActionText::ContentHelper.allowed_attributes = sanitizer_allowed_attributes + %w[rel target]

    content.body.fragment.source.css("a[href]").each do |link|
      uri = URI.parse(link['href'])

      link.set_attribute('rel', 'noreferrer noopener')
      link.set_attribute('target', '_blank')
      link.set_attribute('title', new_tab_suffix(uri.host))
    end

    content
  end
end
