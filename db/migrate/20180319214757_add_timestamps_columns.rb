class AddTimestampsColumns < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :assign_tos, null: true
    add_timestamps :cadastres, null: true
    add_timestamps :drop_down_lists, null: true
    add_timestamps :etablissements, null: true
    add_timestamps :exercices, null: true
    add_timestamps :follows, null: true
    add_timestamps :france_connect_informations, null: true
    add_timestamps :individuals, null: true
    add_timestamps :invites, null: true
    add_timestamps :module_api_cartos, null: true
    add_timestamps :procedure_paths, null: true
    add_timestamps :procedure_presentations, null: true
    add_timestamps :quartier_prioritaires, null: true
    add_timestamps :rna_informations, null: true
    add_timestamps :types_de_champ, null: true
  end
end
