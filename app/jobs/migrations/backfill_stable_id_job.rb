class Migrations::BackfillStableIdJob < ApplicationJob
  queue_as :low_priority

  def perform(dossier_id)
    sql = "UPDATE champs SET stable_id = t.stable_id, stream = 'main'
      FROM types_de_champ t
        WHERE champs.type_de_champ_id = t.id
        AND champs.dossier_id = ?
        AND champs.stable_id IS NULL;"
    query = ActiveRecord::Base.sanitize_sql_array([sql, dossier_id])
    ActiveRecord::Base.connection.execute(query)
  end
end
