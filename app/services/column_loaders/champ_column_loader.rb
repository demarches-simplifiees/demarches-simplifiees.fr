# frozen_string_literal: true

class ColumnLoaders::ChampColumnLoader
  def self.load(champ_columns, dossier_ids)
    Champ
      .where(stable_id: champ_columns.map(&:stable_id), dossier_id: dossier_ids)
      .select(:dossier_id, :value, :stable_id, :type, :external_id, :data, :value_json)
      .group_by(&:stable_id)
      .map do |stable_id, champs|
        columns = champ_columns.filter { |c| c.stable_id == stable_id }

        columns.map do |column|
          champs.map do |champ|
            raw_value = column.value(champ)
            value = ExportedColumnFormatter.format(column:, raw_value:, format: :view)
            { champ.dossier_id => { column.id => value } }
          end.reduce(&:deep_merge)
        end.reduce(&:deep_merge)
      end.reduce(&:deep_merge)
  end
end
