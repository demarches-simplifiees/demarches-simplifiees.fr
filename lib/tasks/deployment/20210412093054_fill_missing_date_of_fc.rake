# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fill_missing_date_of_fc'
  task fill_missing_date_of_fc: :environment do
    rake_puts "Remove invalid FranceConnectInformation records with no associated user…"
    FranceConnectInformation
      .where(user_id: nil)
      .destroy_all

    rake_puts "Fill-in missing created_at from updated_at column on FranceConnectInformation records…"
    created_from_updated_sql = <<~EOF
      created_at = updated_at,
      data = '{ "note": "missing created_at has been copied from updated_at" }'
    EOF

    FranceConnectInformation
      .where(created_at: nil)
      .where.not(updated_at: nil)
      .update_all(created_from_updated_sql)

    rake_puts "Fill-in missing created_at, updated_at columns from users.created on FranceConnectInformation records…"
    created_updated_from_user_created_sql = <<~EOF
      UPDATE france_connect_informations
      SET created_at = users.created_at,
          updated_at = users.created_at,
          data = '{ "note": "missing created_at, updated_at have been copied from users.created_at" }'
      FROM  users
      WHERE users.id = france_connect_informations.user_id
        AND france_connect_informations.created_at IS NULL
        AND france_connect_informations.updated_at IS NULL
    EOF

    FranceConnectInformation
      .connection
      .execute(created_updated_from_user_created_sql)

    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
