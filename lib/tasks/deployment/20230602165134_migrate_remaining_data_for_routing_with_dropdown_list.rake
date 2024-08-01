# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: migrate_remaining_data_for_routing_with_dropdown_list'
  task migrate_remaining_data_for_routing_with_dropdown_list: :environment do
    include Logic
    puts "Running deploy task 'migrate_remaining_data_for_routing_with_dropdown_list'"

    # 301 procedures have a max_duree_conservation_dossiers_dans_ds shorter than the
    # duree_conservation_dossiers_dans_ds. We fix it (otherwise the next request will fail)
    Procedure.with_discarded
      .where('duree_conservation_dossiers_dans_ds > max_duree_conservation_dossiers_dans_ds')
      .update_all('max_duree_conservation_dossiers_dans_ds = duree_conservation_dossiers_dans_ds')

    # First case : routed procedures with only one active group
    # (data had been fixed in lib/tasks/deployment/20221026074507_update_procedure_routing_enabled.rake
    # but not for `with_discarded` procedures)
    Procedure.with_discarded
      .where(routing_enabled: true)
      .filter { |p| p.groupe_instructeurs.active.count == 1 }
      .each do |p|
        p.update!(routing_enabled: false)
      end

    # Second case : procedures not migrated because created during the previous migration
    # (lib/tasks/deployment/20230417083259_migrate_data_for_routing_with_dropdown_list.rake)
    # So we run the same migration again

    procedure_ids = Procedure.with_discarded
      .where(routing_enabled: true)
      .where(migrated_champ_routage: [nil, false])
      .filter { |p| p.active_revision.types_de_champ.none?(&:used_by_routing_rules?) }
      .filter { |p| p.groupe_instructeurs.active.count > 1 }
      .pluck(:id)

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
      end
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
