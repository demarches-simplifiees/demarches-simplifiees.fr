# frozen_string_literal: true

class Columns::JSONPathColumn < Column
  attr_reader :stable_id, :jsonpath, :options_for_select

  def initialize(label:, stable_id:, jsonpath:, options_for_select: [])
    @stable_id = stable_id
    @jsonpath = jsonpath
    @options_for_select = options_for_select

    # currently, the column are searched by id = "#{table}/#{column}"
    # so we have add jsonpath to the column to make it unique
    super(
      table: 'type_de_champ',
      column: "#{stable_id}-#{jsonpath}",
      label:,
      type: options_for_select.any? ? :enum : :text,
    )
  end

  def filtered_ids(dossiers, search_occurences)
    search_term = search_occurences.map { quote_string(_1) }.join('|')
    safe_jsonpath = jsonpath.split('.').map { quote_string(_1) }.join('.')

    condition = %{champs.value_json @? '#{safe_jsonpath} ? (@ like_regex "(#{search_term})" flag "i")'}

    dossiers.with_type_de_champ(stable_id)
      .where(condition)
      .ids
  end

  def champ_value(champ)
    Hash(champ.value_json).dig(*jsonpath_to_array)
  end

  def jsonpath_to_array
    jsonpath.split('$.').second.split('.')
  end

  private

  def quote_string(string) = ActiveRecord::Base.connection.quote_string(string)
end
