class Facet
  attr_reader :table, :column, :label, :classname, :virtual, :type, :scope, :value_column, :filterable

  def initialize(table:, column:, label: nil, virtual: false, type: :text, value_column: :value, filterable: true, classname: '', scope: '')
    @table = table
    @column = column
    @label = label || I18n.t(column, scope: [:activerecord, :attributes, :procedure_presentation, :fields, table])
    @classname = classname
    @virtual = virtual
    @type = type
    @scope = scope
    @value_column = value_column
    @filterable = filterable
  end

  def id
    "#{table}/#{column}"
  end

  # ??? p-e que le filtre peut avoir
  # -> .serialize (field_id)
  # -> .type
  # -> .to_enum ? (field_enum(field_id))
  # -> .to_sql? ou .to_filter? (filtered_ids)
  # -> .humanize_value (human_value_for_filter)
  # -> .sorted_on_me(ProcedurePresentation.sort)
  # -> .aria_sort # p-e a extraire en vue
  #
  def ==(other)
    other.to_json == to_json
  end

  def to_json
    {
      table:, column:, label:, classname:, virtual:, type:, scope:, value_column:, filterable:
    }
  end
end
