# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: remove_unused_column_on_type_de_champs'
  task remove_unused_column_on_type_de_champs: :environment do
    puts "Running deploy task 'remove_unused_column_on_type_de_champs'"

    StrongMigrations.disable_check :remove_column

    ActiveRecord::Migration.remove_column :types_de_champ, :migrated_parent
    ActiveRecord::Migration.remove_column :types_de_champ, :revision_id
    ActiveRecord::Migration.remove_column :types_de_champ, :parent_id
    ActiveRecord::Migration.remove_column :types_de_champ, :order_place

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
