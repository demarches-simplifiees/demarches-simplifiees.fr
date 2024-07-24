class Facet
  attr_reader :table, :column, :label, :classname, :virtual, :type, :scope, :value_column, :filterable

  def initialize(table:, column:, label: nil, virtual: false, type: :text, value_column: :value, filterable: true, classname: '', scope: '', options_for_select: nil)
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

  def self.make_id(table, column)
    [table, column].join('/')
  end

  def id
    Facet.make_id(table, column)
  end

  def ==(other)
    other.to_json == to_json
  end

  def to_json
    {
      table:, column:, label:, classname:, virtual:, type:, scope:, value_column:, filterable:
    }
  end
end
