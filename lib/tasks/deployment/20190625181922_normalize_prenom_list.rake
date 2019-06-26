namespace :after_party do
  desc 'Deployment task: normalize comma separated list of prenom'
  task normalize_prenom_list: :environment do
    puts "Running deploy task 'normalize_prenom_list'"

    Individual.find_each { |individual| sanitize_prenom(individual) }

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20190625181922'
  end # task :normalize_prenom_list

  def sanitize_prenom(individual)
    begin
      if individual.prenom
        individual.update_column(:prenom, individual.prenom.gsub(/[[:space:]]+/, ' ').strip.gsub(/(?<=[^[:alnum:]]|^)([[:alnum:]])([[:alnum:]]+)/) { "#{$1.capitalize}#{$2.downcase}" })
      end
    rescue
    end
  end
end # namespace :after_party
