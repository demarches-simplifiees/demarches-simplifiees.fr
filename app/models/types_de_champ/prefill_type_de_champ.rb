# frozen_string_literal: true

class TypesDeChamp::PrefillTypeDeChamp < SimpleDelegator
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  POSSIBLE_VALUES_THRESHOLD = 5

  def initialize(type_de_champ, revision)
    super(type_de_champ)
    @revision = revision
  end

  def self.build(type_de_champ, revision)
    case type_de_champ.type_champ
    when TypeDeChamp.type_champs.fetch(:drop_down_list)
      TypesDeChamp::PrefillDropDownListTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:multiple_drop_down_list)
      TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:pays)
      TypesDeChamp::PrefillPaysTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:regions)
      TypesDeChamp::PrefillRegionTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:repetition)
      TypesDeChamp::PrefillRepetitionTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:departements)
      TypesDeChamp::PrefillDepartementTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:communes)
      TypesDeChamp::PrefillCommuneTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:address)
      TypesDeChamp::PrefillAddressTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:epci)
      TypesDeChamp::PrefillEpciTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:formatted)
      TypesDeChamp::PrefillFormattedTypeDeChamp.new(type_de_champ, revision)
    when TypeDeChamp.type_champs.fetch(:siret)
      TypesDeChamp::PrefillSiretTypeDeChamp.new(type_de_champ, revision)
    else
      new(type_de_champ, revision)
    end
  end

  def self.wrap(collection, revision)
    collection.map { |type_de_champ| build(type_de_champ, revision) }
  end

  def possible_values
    values = []
    values << description if description.present?
    if too_many_possible_values?
      values << link_to_all_possible_values
    else
      values << all_possible_values.to_sentence
    end
    values.compact.join('<br>').html_safe # rubocop:disable Rails/OutputSafety
  end

  def all_possible_values
    []
  end

  def example_value
    return nil unless prefillable?

    I18n.t("views.prefill_descriptions.edit.examples.#{type_champ}")
  end

  def to_assignable_attributes(champ, value)
    { id: champ.id, value: value }
  end

  private

  def link_to_all_possible_values
    return unless prefillable?

    link_to(
      I18n.t("views.prefill_descriptions.edit.possible_values.link.text"),
      Rails.application.routes.url_helpers.prefill_type_de_champ_path(@revision.procedure_path, self),
      title: new_tab_suffix(I18n.t("views.prefill_descriptions.edit.possible_values.link.title")),
      **external_link_attributes
    )
  end

  def too_many_possible_values?
    all_possible_values.count > POSSIBLE_VALUES_THRESHOLD
  end

  def description
    @description ||= I18n.t("views.prefill_descriptions.edit.possible_values.#{type_champ}_html", default: nil)&.html_safe
  end
end
