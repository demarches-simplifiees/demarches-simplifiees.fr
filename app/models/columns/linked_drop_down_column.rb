# frozen_string_literal: true

class Columns::LinkedDropDownColumn < Columns::ChampColumn
  attr_reader :path

  def initialize(procedure_id:, label:, stable_id:, tdc_type:, path:, options_for_select: [], displayable:, type: :text, mandatory:)
    @path = path

    super(
      procedure_id:,
      label:,
      stable_id:,
      tdc_type:,
      displayable:,
      type:,
      options_for_select:,
      mandatory:
    )
  end

  def filtered_ids(dossiers, filter)
    case filter
    in { operator: 'match', value: Array }
      filtered_ids_for_values(dossiers, filter[:value])
    else
      Sentry.capture_message("Unknown filter: #{filter}")
      dossiers.ids
    end
  end

  def filtered_ids_for_values(dossiers, search_terms)
    relation = dossiers.with_type_de_champ(@stable_id)

    case path
    when :value
      search_terms.flat_map do |search_term|
        # when looking for "section 1 / option A",
        # the value must contain both "section 1" and "option A"
        primary, *secondary = search_term.split(%r{[[:space:]]*/[[:space:]]*})
        safe_terms = [primary, *secondary].map { "%#{safe_like(_1)}%" }

        relation.where("champs.value ILIKE ALL (ARRAY[?])", safe_terms).ids
      end.uniq
    when :primary
      primary_terms = search_terms.map { |term| %{["#{safe_like(term)}","%"]} }

      relation.where("champs.value ILIKE ANY (array[?])", primary_terms).ids
    when :secondary
      secondary_terms = search_terms.map { |term| %{["%","#{safe_like(term)}"]} }

      relation.where("champs.value ILIKE ANY (array[?])", secondary_terms).ids
    end
  end

  private

  def column_id = "type_de_champ/#{stable_id}.#{path}"

  def typed_value(champ)
    primary_value, secondary_value = unpack_values(champ.value)
    case path
    when :value
      "#{primary_value} / #{secondary_value}"
    when :primary
      primary_value
    when :secondary
      secondary_value
    end
  end

  def unpack_values(value)
    JSON.parse(value)
  rescue JSON::ParserError,
         TypeError # case of value.nil?.eq(true)
    []
  end

  def safe_like(q) = ActiveRecord::Base.sanitize_sql_like(q)
end
