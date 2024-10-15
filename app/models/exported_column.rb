# frozen_string_literal: true

class ExportedColumn
  attr_reader :column, :libelle

  def initialize(column:, libelle:)
    @column = column
    @libelle = libelle
  end
end
