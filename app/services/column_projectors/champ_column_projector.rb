# frozen_string_literal: true

class ColumnProjectors::ChampColumnProjector
  def self.project(columns, dossiers)
    dossier_ids = dossiers.map(&:id)

    champs = Champ
      .where(stable_id: columns.map(&:stable_id), dossier_id: dossier_ids)
      .select(:dossier_id, :value, :stable_id, :type, :external_id, :data, :value_json)

    columns_for = columns.group_by(&:stable_id)

    all_h = champs.flat_map { |champ| columns_for[champ.stable_id].map { |column| h(column, champ) } }

    all_h.reduce(&:deep_merge)
  end

  private

  def self.h(column, champ)
    raw_value = column.value(champ)

    {
      champ.dossier_id => {
        column.id => ExportedColumnFormatter.format(column:, raw_value:, format: :html)
      }
    }
  end
end

# essayer de faire le formatage dans un view component qui prendrait Column, et Dossier/ ou champ suivant comment marche Column.value
