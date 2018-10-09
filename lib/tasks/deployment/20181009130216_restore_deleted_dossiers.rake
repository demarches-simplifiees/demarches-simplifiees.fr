require Rails.root.join("lib", "tasks", "task_helper")

namespace :after_party do
  desc 'Deployment task: restore_deleted_dossiers'
  task restore_deleted_dossiers: :environment do
    Class.new do
      def run
        rake_puts "Running deploy task 'restore_deleted_dossiers'"
        restore_candidats_libres_deleted_dossiers
        AfterParty::TaskRecord.create version: '20181009130216'
      end

      def restore_candidats_libres_deleted_dossiers
        mapping = Class.new(Tasks::DossierProcedureMigrator::ChampMapping) do
          def setup_mapping
            champ_opts = {
              16 => {
                source_overrides: { 'libelle' => 'Adresse postale du candidat' },
                destination_overrides: { 'libelle' => 'Adresse postale complète du candidat' }
              }
            }
            (0..23).each do |i|
              map_source_to_destination_champ(i, i, **(champ_opts[i] || {}))
            end
          end
        end

        private_mapping = Class.new(Tasks::DossierProcedureMigrator::ChampMapping) do
          def setup_mapping
            compute_destination_champ(
              TypeDeChamp.new(
                type_champ: 'datetime',
                order_place: 0,
                libelle: 'Date et heure de convocation',
                mandatory: false
              )
            ) do |d, target_tdc|
              target_tdc.champ.create(dossier: d)
            end
            compute_destination_champ(
              TypeDeChamp.new(
                type_champ: 'text',
                order_place: 1,
                libelle: 'Lieu de convocation',
                mandatory: false
              )
            ) do |d, target_tdc|
              target_tdc.champ.create(dossier: d)
            end
            compute_destination_champ(
              TypeDeChamp.new(
                type_champ: 'address',
                order_place: 2,
                libelle: 'Adresse centre examen',
                mandatory: false
              )
            ) do |d, target_tdc|
              target_tdc.champ.create(dossier: d)
            end
          end
        end

        pj_mapping = Class.new(Tasks::DossierProcedureMigrator::PieceJustificativeMapping) do
          def setup_mapping
            (0..3).each do |i|
              map_source_to_destination_pj(i, i + 2)
            end
            leave_destination_pj_blank(
              TypeDePieceJustificative.new(
                order_place: 0,
                libelle: "Télécharger la Charte de l'accompagnateur"
              )
            )
            leave_destination_pj_blank(
              TypeDePieceJustificative.new(
                order_place: 1,
                libelle: "Télécharger l'attestation d'assurance"
              )
            )
          end
        end

        restore_deleted_dossiers(4860, 8603, mapping, private_mapping, pj_mapping)
      end

      def restore_deleted_dossiers(deleted_procedure_id, new_procedure_id, champ_mapping, champ_private_mapping, pj_mapping)
        Dossier.unscoped
          .joins('JOIN procedures ON procedures.id = dossiers.procedure_id')
          .where(procedure_id: deleted_procedure_id)
          .where('dossiers.hidden_at >= procedures.hidden_at')
          .update_all(hidden_at: nil)

        source_procedure = Procedure.unscoped.find(deleted_procedure_id)
        destination_procedure = Procedure.find(new_procedure_id)

        migrator = Tasks::DossierProcedureMigrator.new(source_procedure, destination_procedure, champ_mapping, champ_private_mapping, pj_mapping)
        migrator.check_consistency
        migrator.migrate_dossiers
      end
    end.new.run
  end
end
