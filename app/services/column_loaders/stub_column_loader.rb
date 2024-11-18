# frozen_string_literal: true

class ColumnLoaders::StubColumnLoader
  def self.load(columns, dossier_ids)
    dossier_ids.map do |dossier_id|
      { dossier_id => columns.to_h { |column| [column.id, nil] } }
    end.reduce(:merge)
  end
end
