module ReleaseNotesHelper
  def announce_category_badge(category)
    color_class = case category.to_sym
    when :administrateur
      'fr-background-flat--blue-france fr-text-inverted--blue-france'
    when :instructeur
      'fr-background-contrast--yellow-tournesol'
    when :expert
      'fr-background-contrast--purple-glycine'
    when :usager
      'fr-background-contrast--green-emeraude'
    when :api
      'fr-background-contrast--blue-ecume'
    end

    content_tag(:span, ReleaseNote.human_attribute_name("categories.#{category}"), class: "fr-badge #{color_class}")
  end
end
