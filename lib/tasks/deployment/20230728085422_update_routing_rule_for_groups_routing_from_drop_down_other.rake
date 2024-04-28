# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: update_routing_rule_for_groups_routing_from_drop_down_other'
  task update_routing_rule_for_groups_routing_from_drop_down_other: :environment do
    puts "Running deploy task 'update_routing_rule_for_groups_routing_from_drop_down_other'"

    # Put your task implementation HERE.
    include Logic

    GroupeInstructeur
      .joins(:procedure)
      .where(procedures: { routing_enabled: true })
      .in_batches do |groupe_instructeurs|
        groupe_instructeurs
          .filter { |gi| gi.routing_rule.present? && gi.routing_rule.right.value == 'Autre' }
          .each { |gi| gi.update(routing_rule: ds_eq(gi.routing_rule.left, constant('__other__'))) }
      end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
