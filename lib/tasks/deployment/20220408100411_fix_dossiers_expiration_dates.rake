# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_dossiers_expiration_dates'
  task fix_dossiers_expiration_dates: :environment do
    puts "Running deploy task 'fix_dossiers_expiration_dates'"

    duree_conservation = "procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month'"

    expiration_after_notice_brouillon = "dossiers.brouillon_close_to_expiration_notice_sent_at + INTERVAL '#{Dossier::INTERVAL_EXPIRATION}'"
    expiration_with_extention_brouillon = "dossiers.created_at + dossiers.conservation_extension + (#{duree_conservation}) - INTERVAL '#{Dossier::INTERVAL_BEFORE_EXPIRATION}'"
    dossiers_brouillon = Dossier
      .joins(:procedure)
      .state_brouillon
      .visible_by_user
      .where.not(brouillon_close_to_expiration_notice_sent_at: nil)
      .where.not(conservation_extension: 0.seconds)
      .where("(#{expiration_after_notice_brouillon}) < (#{expiration_with_extention_brouillon})")

    expiration_after_notice_en_construction = "dossiers.en_construction_close_to_expiration_notice_sent_at + INTERVAL '#{Dossier::INTERVAL_EXPIRATION}'"
    expiration_with_extention_en_construction = "dossiers.en_construction_at + dossiers.conservation_extension + (#{duree_conservation}) - INTERVAL '#{Dossier::INTERVAL_BEFORE_EXPIRATION}'"
    dossiers_en_construction = Dossier
      .joins(:procedure)
      .state_en_construction
      .visible_by_user_or_administration
      .where.not(en_construction_close_to_expiration_notice_sent_at: nil)
      .where.not(conservation_extension: 0.seconds)
      .where("(#{expiration_after_notice_en_construction}) < (#{expiration_with_extention_en_construction})")

    expiration_after_notice_termine = "dossiers.termine_close_to_expiration_notice_sent_at + INTERVAL '#{Dossier::INTERVAL_EXPIRATION}'"
    expiration_with_extention_termine = "dossiers.processed_at + dossiers.conservation_extension + (#{duree_conservation}) - INTERVAL '#{Dossier::INTERVAL_BEFORE_EXPIRATION}'"
    dossiers_termine = Dossier
      .joins(:procedure)
      .state_termine
      .visible_by_user_or_administration
      .where.not(termine_close_to_expiration_notice_sent_at: nil)
      .where.not(conservation_extension: 0.seconds)
      .where("(#{expiration_after_notice_termine}) < (#{expiration_with_extention_termine})")

    rake_puts "brouillon: #{dossiers_brouillon.count}"
    rake_puts "en_construction: #{dossiers_en_construction.count}"
    rake_puts "termine: #{dossiers_termine.count}"

    dossiers_brouillon.update_all(brouillon_close_to_expiration_notice_sent_at: nil)
    dossiers_en_construction.update_all(en_construction_close_to_expiration_notice_sent_at: nil)
    dossiers_termine.update_all(termine_close_to_expiration_notice_sent_at: nil)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
