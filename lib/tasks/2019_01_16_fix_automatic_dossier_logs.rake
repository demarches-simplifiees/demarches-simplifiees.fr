class FixAutomaticDossierLogs_2019_01_16
  def find_handlers
    # rubocop:disable Security/YAMLLoad
    Delayed::Job.where(queue: 'cron')
      .map { |job| YAML.load(job.handler) }
      .select { |handler| handler.job_data['job_class'] == 'AutoReceiveDossiersForProcedureJob' }
    # rubocop:enable Security/YAMLLoad
  end

  def run
    handlers = find_handlers

    handlers
      .map { |handler| handler.job_data['arguments'] }
      .each do |(procedure_id, state)|

      procedure = Procedure
        .includes(:administrateur, dossiers: [:dossier_operation_logs, :follows])
        .find(procedure_id)

      rake_puts "working on procedure #{procedure_id}, #{procedure.libelle} whose admin is #{procedure.administrateur.email}"

      case state
      when Dossier.states.fetch(:en_instruction)
        dossiers = procedure.dossiers.state_en_instruction
        operation = 'passer_en_instruction'
      when Dossier.states.fetch(:accepte)
        dossiers = procedure.dossiers.accepte
        operation = 'accepter'
      end

      dossier_operation_logs = DossierOperationLog
        .where(dossier: dossiers, operation: operation)

      rake_puts "affecting #{dossier_operation_logs.count} dossier_operation_logs"

      dossier_operation_logs
        .update_all(gestionnaire_id: nil, automatic_operation: true)

      # if the dossier is only followed by the procedure administrateur
      # unfollow
      if state == Dossier.states.fetch(:en_instruction)
        dossier_to_unfollows = dossiers
          .select { |d| d.follows.count == 1 && d.follows.first.gestionnaire.email == procedure.administrateur.email }

        rake_puts "affecting #{dossier_to_unfollows.count} dossiers"

        dossier_to_unfollows
          .each { |d| d.follows.destroy_all }
      end

      rake_puts ""
    end
  end
end

namespace :'2019_01_16_fix_automatic_dossier_logs' do
  task run: :environment do
    FixAutomaticDossierLogs_2019_01_16.new.run
  end
end
