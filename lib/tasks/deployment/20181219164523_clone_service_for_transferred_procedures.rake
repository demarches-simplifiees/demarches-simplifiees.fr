require Rails.root.join("lib", "tasks", "task_helper")

namespace :after_party do
  desc 'Deployment task: clone_service_for_transferred_procedures'
  task clone_service_for_transferred_procedures: :environment do
    rake_puts "Running deploy task 'clone_service_for_transferred_procedures'"

    procedures = Procedure.includes(:service).where.not(service_id: nil)
    procedures_to_fix_in_array = procedures.select do |p|
      p.administrateur_id != p.service.administrateur_id
    end
    procedures_to_fix = Procedure.where(id: procedures_to_fix_in_array.map(&:id))

    service_and_admin_list = procedures_to_fix.group(:service_id, :administrateur_id).count.keys
    progress = ProgressReport.new(service_and_admin_list.count)

    service_and_admin_list.each do |service_id, administrateur_id|
      cloned_service = Service.find(service_id).clone_and_assign_to_administrateur(Administrateur.find(administrateur_id))

      if cloned_service.save
        rake_puts "Fixing Service #{service_id} for Administrateur #{administrateur_id}"
        procedures_to_fix
          .where(service_id: service_id, administrateur_id: administrateur_id)
          .update_all(service_id: cloned_service.id)
      else
        rake_puts "Cannot fix Service #{service_id} for Administrateur #{administrateur_id}, it should be fixed manually. Errors : #{cloned_service.errors.full_messages}"
      end
      progress.inc
    end

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20181219164523'
  end # task :clone_service_for_transferred_procedures
end # namespace :after_party
