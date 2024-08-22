# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: drop_down_list_options_to_json'
  task drop_down_list_options_to_json: :environment do
    puts "Running deploy task 'drop_down_list_options_to_json'"

    begin
      types_de_champ = TypeDeChamp.joins(:drop_down_list).where(type_champ: [
        TypeDeChamp.type_champs.fetch(:drop_down_list),
        TypeDeChamp.type_champs.fetch(:multiple_drop_down_list),
        TypeDeChamp.type_champs.fetch(:linked_drop_down_list)
      ])

      progress = ProgressReport.new(types_de_champ.count)

      types_de_champ.find_each do |type_de_champ|
        type_de_champ.drop_down_list_value = type_de_champ.drop_down_list_value

        if type_de_champ.save
          type_de_champ.drop_down_list.destroy
        end

        progress.inc
      end

      progress.finish
    rescue ActiveRecord::ConfigurationError => e
      warn e.message
      puts "Skip deploy task."
    ensure
      # Update task as completed.  If you remove the line below, the task will
      # run with every deploy (or every time you call after_party:run).
      AfterParty::TaskRecord.create version: '20200618121241'
    end
  end
end
