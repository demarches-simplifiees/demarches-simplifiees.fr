require Rails.root.join("lib", "tasks", "task_helper")

namespace :after_party do
  desc 'Deployment task: delete_dossiers_without_procedure'
  task delete_dossiers_without_procedure: :environment do
    rake_puts "Running deploy task 'delete_dossiers_without_procedure'"

    dossiers_without_procedure = Dossier.left_outer_joins(:procedure).where(procedures: { id: nil })
    total = dossiers_without_procedure.count
    expected_dossiers_count = 60

    if total > expected_dossiers_count
      raise "Error: #{expected_dossiers_count} dossiers expected, but found #{total}. Aborting."
    end

    dossiers_without_procedure.each do |dossier|
      rake_puts "Destroy dossier #{dossier.id}"
      dossier.destroy!
    end

    rake_puts "#{total} dossiers without procedure were destroyed."

    AfterParty::TaskRecord.create version: '20190117154829'
  end # task :delete_dossiers_without_procedure
end # namespace :after_party
