class RemoveUselessForeignKeys < ActiveRecord::Migration[5.2]
  @@rfks = {
    :administrateurs_gestionnaires => [:administrateurs, :gestionnaires],
    :administrateurs_procedures => [:administrateurs, :procedures],
    :assign_tos => [:gestionnaires, :procedures],
    :champs => [:dossiers, :types_de_champ],
    :deleted_dossiers => [:dossiers, :procedures],
    :dossiers => [:procedures],
    :pieces_justificatives => [:dossiers, :types_de_piece_justificative],
    :types_de_champ => [:procedures],
    :types_de_piece_justificative => [:procedures]
  }

  @@afks = {
    :procedures => [:services]
  }

  @@rindexes = [
    { table: :deleted_dossiers, column: :dossier_id, name: "idx_deleted_dossiers_dossier_id" },
    { table: :types_de_champ, column: :procedure_id, name: "idx_types_de_champ_procedure_id" },
    { table: :types_de_piece_justificative, column: :procedure_id, name: "idx_types_de_piece_justificative_procedure_id" }
  ]

  def up
    remove_foreign_keys(@@rfks)
    add_foreign_keys(@@afks)
    remove_indexes(@@rindexes)
  end

  def down
    add_indexes(@@rindexes)
    remove_foreign_keys(@@afks)
    add_foreign_keys(@@rfks)
  end

  private

  def remove_foreign_keys(foreign_keys)
    foreign_keys.each do |source, destinations|
      destinations.each do |destination|
        if foreign_key_exists?(source, destination)
          remove_foreign_key source, destination
        end
      end
    end
  end

  def add_foreign_keys(add)
    add.each do |source, destinations|
      destinations.each do |destination|
        unless foreign_key_exists?(source, destination)
          add_foreign_key source, destination, name: "fk_#{source}_#{destination}"
        end
      end
    end
  end

  def remove_indexes(indexes)
    indexes.each do |params|
      if index_name_exists?(params[:table], params[:name])
        remove_index params[:table], params
      end
    end
  end

  def add_indexes(add)
    indexes.each do |params|
      unless index_name_exists?(params[:table], params[:name])
        add_index params[:table], params
      end
    end
  end
end
