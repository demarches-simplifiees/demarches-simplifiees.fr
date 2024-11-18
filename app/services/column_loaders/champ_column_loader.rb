# frozen_string_literal: true

class ColumnLoaders::ChampColumnLoader
  def self.load(columns, dossier_ids)
    Champ
      .where(stable_id: columns.map(&:stable_id), dossier_id: dossier_ids)
      .select(:dossier_id, :value, :stable_id, :type, :external_id, :data, :value_json)
      .group_by(&:dossier_id)
      .map { |dossier_id, champs| load_one_dossier(dossier_id, champs, columns) }
      .reduce(&:merge)
  end

  private

  def self.load_one_dossier(dossier_id, champs, columns)
    { dossier_id => columns.map { |c| load_one_column(c, champs) }.reduce(:merge) }
  end

  def self.load_one_column(column, champs)
    champ = champs.find { |c| c.stable_id == column.stable_id }

    raw_value = column.value(champ)
    { column.id => ExportedColumnFormatter.format(column:, raw_value:, format: :view) }
  end
end
