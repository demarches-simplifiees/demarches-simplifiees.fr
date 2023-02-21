class TypesDeChamp::PrefillRepetitionTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  def possible_values
    [
      I18n.t("views.prefill_descriptions.edit.possible_values.#{type_champ}_html"),
      subchamps_all_possible_values
    ].join("</br>").html_safe # rubocop:disable Rails/OutputSafety
  end

  def example_value
    [row_values_format, row_values_format].map { |row| row.to_s.gsub("=>", ":") }
  end

  def to_assignable_attributes(champ, value)
    return [] unless value.is_a?(Array)

    value.map.with_index do |repetition, index|
      PrefillRepetitionRow.new(champ, repetition, index, @revision).to_assignable_attributes
    end.reject(&:blank?)
  end

  private

  def subchamps_all_possible_values
    "<ul>" + prefillable_subchamps.map do |prefill_type_de_champ|
      "<li>#{prefill_type_de_champ.to_typed_id}: #{prefill_type_de_champ.possible_values}</li>"
    end.join + "</ul>"
  end

  def row_values_format
    @row_example_value ||=
      prefillable_subchamps.map do |prefill_type_de_champ|
      [prefill_type_de_champ.to_typed_id, prefill_type_de_champ.example_value.to_s]
    end.to_h
  end

  def prefillable_subchamps
    @prefillable_subchamps ||=
      TypesDeChamp::PrefillTypeDeChamp.wrap(@revision.children_of(self).filter(&:prefillable?), @revision)
  end

  class PrefillRepetitionRow
    attr_reader :champ, :repetition, :index, :revision

    def initialize(champ, repetition, index, revision)
      @champ = champ
      @repetition = repetition
      @index = index
      @revision = revision
    end

    def to_assignable_attributes
      row = champ.rows[index] || champ.add_row(champ.dossier_revision)

      JSON.parse(repetition).map do |key, value|
        subchamp = row.find { |champ| champ.type_de_champ_to_typed_id == key }
        next unless subchamp

        TypesDeChamp::PrefillTypeDeChamp.build(subchamp.type_de_champ, revision).to_assignable_attributes(subchamp, value)
      rescue JSON::ParserError # On ignore les valeurs qu'on n'arrive pas à parser
      end.compact
    end
  end
end
