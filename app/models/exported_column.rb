# frozen_string_literal: true

class ExportedColumn
  attr_reader :column, :libelle

  def initialize(column:, libelle:)
    @column = column
    @libelle = libelle
  end

  def id = { id: column.id, libelle: }.to_json

  def libelle_with_value(champ_or_dossier)
    [libelle, column.value(champ_or_dossier)]
  end
end
