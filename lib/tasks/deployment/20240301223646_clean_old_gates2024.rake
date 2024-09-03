# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: clean_old_gates2024'
  task clean_old_gates2024: :environment do
    puts "Running deploy task 'clean_old_gates2024'"

    keys = [
      'admin_affect_experts_to_avis',
      'chorus',
      'disable_label_optional_champ_2023_06_29',
      'expert_not_allowed_to_invite',
      'instructeur_bypass_email_login_token',
      'multi_line_routing',
      'opendata',
      'procedure_conditional',
      'procedure_routage_api',
      'rerouting',
      'routing_rules',
      'zonage'
    ]

    Flipper::Adapters::ActiveRecord::Gate.where(feature_key: keys).delete_all
    Flipper::Adapters::ActiveRecord::Feature.where(key: keys).delete_all

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
