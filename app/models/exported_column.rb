# frozen_string_literal: true

class ExportedColumn
  attr_reader :column, :libelle, :parent

  def initialize(column:, libelle:, parent: nil)
    @column = column
    @libelle = libelle
    @parent = parent
  end
end
