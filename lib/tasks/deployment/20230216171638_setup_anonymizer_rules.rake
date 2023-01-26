if ENV["PG_ANONYMIZER_ROLE"].present?
  namespace :after_party do
    desc 'Deployment task: setup_anonymizer_rules'
    task setup_anonymizer_rules: :environment do
      puts "Running deploy task 'setup_anonymizer_rules'"

      Rake::Task["anonymizer:setup_rules"].invoke

      AfterParty::TaskRecord
        .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
    end
  end
end
