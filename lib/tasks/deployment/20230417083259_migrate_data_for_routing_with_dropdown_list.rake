# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_data_for_routing_with_dropdown_list'
  task migrate_data_for_routing_with_dropdown_list: :environment do
    include Logic
    puts "Running deploy task 'migrate_data_for_routing_with_dropdown_list'"

    # Put your task implementation HERE.
    procedure_ids = GroupeInstructeur
      .joins(:procedure)
      .where(procedures: { migrated_champ_routage: [nil, false] })
      .group(:procedure_id)
      .having("count(groupe_instructeurs.id) > 1")
      .pluck(:procedure_id)

    progress = ProgressReport.new(procedure_ids.count)

    procedure_ids.each do |procedure_id|
      procedure = Procedure.with_discarded.find(procedure_id)
      procedure.transaction do
        routage_type_de_champ = TypeDeChamp.create!(
          type_champ: 'drop_down_list',
          libelle: procedure.routing_criteria_name || 'Votre ville',
          options: { "drop_down_options" => [''] + procedure.groupe_instructeurs.active.pluck(:label) },
          private: false,
          mandatory: true
        )

        ProcedureRevisionTypeDeChamp
          .joins(:revision)
          .where(procedure_revisions: { procedure_id: }, parent_id: nil)
          .update_all('position = position + 1')

        # add routage_type_de_champ sur les positions
        now = Time.zone.now
        to_insert = procedure.revisions.ids.map do |revision_id|
          { revision_id:, type_de_champ_id: routage_type_de_champ.id, position: 0, created_at: now, updated_at: now }
        end
        ProcedureRevisionTypeDeChamp.insert_all(to_insert)

        procedure.groupe_instructeurs.each do |gi|
          gi.update_columns(routing_rule: ds_eq(champ_value(routage_type_de_champ.stable_id), constant(gi.label)))
        end

        procedure.update_columns(migrated_champ_routage: true)

        #  Ajouter un chp drpdwn ds chq dossier
        insert_dropdown_champ_sql = <<~EOF
          INSERT INTO champs ( type, value, type_de_champ_id, dossier_id, private, created_at, updated_at )
          #{procedure.dossiers.left_joins(:groupe_instructeur).select("'Champs::DropDownListChamp', groupe_instructeurs.label, '#{routage_type_de_champ.id}', dossiers.id, false, dossiers.created_at, dossiers.created_at").to_sql}
        EOF
        ActiveRecord::Base.connection.execute(insert_dropdown_champ_sql)

        Flipper.enable(:routing_rules, procedure)
      end
      Flipper.enable(:routing_rules)
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
