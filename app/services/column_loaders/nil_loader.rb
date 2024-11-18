# frozen_string_literal: true

class ColumnLoaders::NilLoader
  def self.load(columns, dossier_ids)
    dossier_ids.flat_map do |dossier_id|
      { dossier_id => columns.to_h { |column| [column.id, nil] } }
    end.reduce(&:deep_merge)
  end
end
