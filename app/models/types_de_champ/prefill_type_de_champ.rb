class TypesDeChamp::PrefillTypeDeChamp < SimpleDelegator
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  POSSIBLE_VALUES_THRESHOLD = 5

  def self.build(type_de_champ)
    case type_de_champ.type_champ
    when TypeDeChamp.type_champs.fetch(:drop_down_list)
      TypesDeChamp::PrefillDropDownListTypeDeChamp.new(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:pays)
      TypesDeChamp::PrefillPaysTypeDeChamp.new(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:regions)
      TypesDeChamp::PrefillRegionTypeDeChamp.new(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:repetition)
      TypesDeChamp::PrefillRepetitionTypeDeChamp.new(type_de_champ)
    else
      new(type_de_champ)
    end
  end

  def self.wrap(collection)
    collection.map { |type_de_champ| build(type_de_champ) }
  end

  def possible_values
    [possible_values_list_display, link_to_all_possible_values].compact.join('<br>').html_safe # rubocop:disable Rails/OutputSafety
  end

  def example_value
    return nil unless prefillable?

    I18n.t("views.prefill_descriptions.edit.examples.#{type_champ}")
  end

  def formatted_example_value
    "\"#{example_value}\"" if example_value.present?
  end

  def to_assignable_attributes(champ, value)
    { id: champ.id, value: value }
  end

  private

  def possible_values_list
    return [] unless prefillable?

    [I18n.t("views.prefill_descriptions.edit.possible_values.#{type_champ}_html")]
  end

  def link_to_all_possible_values
    return unless too_many_possible_values? && prefillable?

    link_to I18n.t("views.prefill_descriptions.edit.possible_values.link.text"), Rails.application.routes.url_helpers.prefill_type_de_champ_path(path, self), title: new_tab_suffix(I18n.t("views.prefill_descriptions.edit.possible_values.link.title")), **external_link_attributes
  end

  def too_many_possible_values?
    possible_values_list.count > POSSIBLE_VALUES_THRESHOLD
  end

  def possible_values_list_display
    if too_many_possible_values?
      I18n.t("views.prefill_descriptions.edit.possible_values.#{type_champ}_html").html_safe # rubocop:disable Rails/OutputSafety
    else
      possible_values_list.to_sentence
    end
  end
end
