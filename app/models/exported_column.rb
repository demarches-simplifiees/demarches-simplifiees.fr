# frozen_string_literal: true

class ExportedColumn
  attr_reader :column, :libelle

  def initialize(column:, libelle:)
    @column = column
    @libelle = libelle
  end

  def id = { id: column.id, libelle: }.to_json

  def libelle_with_value(champ_or_dossier, format:)
    [libelle, ExportedColumnFormatter.format(column:, champ_or_dossier:, format:), spreadsheet_architect_type]
  end

  # see: https://github.com/westonganger/spreadsheet_architect/blob/771e2e5558fbf6e0cb830e881a7214fa710e49c3/lib/spreadsheet_architect.rb#L39
  def spreadsheet_architect_type
    case @column.type
    when :boolean
      :boolean
    when :decimal
      :float
    when :number
      :integer
    when :datetime
      :time
    when :date
      :date
    else
      :string
    end
  end
end
