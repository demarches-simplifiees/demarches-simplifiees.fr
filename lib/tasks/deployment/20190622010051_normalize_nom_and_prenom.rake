namespace :after_party do
  desc 'Deployment task: upcase nom and camelcase prenom'
  task normalize_nom_and_prenom: :environment do
    puts "Running deploy task 'normalize_nom_and_prenom'"

    Individual.all.find_each { |individual| sanitize_names(individual) }

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190622010051'
  end # task :normalize_nom_and_prenom

  def sanitize_names(individual)
    begin
      individual.update_column(:nom, individual.nom.gsub(/[[:space:]]/, ' ').strip.upcase)
      individual.update_column(:prenom, individual.prenom.gsub(/[[:space:]]/, ' ').strip.gsub(/(?<=[^[:alnum:]]|^)(.)([[:alnum:]]+)/) { "#{$1.capitalize}#{$2.downcase}" })
    rescue
    end
  end
end # namespace :after_party
