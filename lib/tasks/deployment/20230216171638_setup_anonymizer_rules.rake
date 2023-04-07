namespace :after_party do
  desc 'Deployment task: setup_anonymizer_rules'
  task setup_anonymizer_rules: :environment do
    puts "Running deploy task 'setup_anonymizer_rules'"

    Rake::Task["anonymizer:setup_rules"].invoke

    # We want this task to run at each deployment
  end
end
