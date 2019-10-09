namespace :after_party do
  desc 'Deployment task: update_admin_last_sign_in_at'
  task update_admin_last_sign_in_at: :environment do
    sql = <<-SQL
      UPDATE users
      SET last_sign_in_at = administrateurs.updated_at
      FROM administrateurs
      WHERE administrateur_id = administrateurs.id
        AND users.last_sign_in_at IS NULL
        AND administrateurs.active = true
    SQL

    ActiveRecord::Base.connection.execute(sql)

    AfterParty::TaskRecord.create version: '20191007124230'
  end
end
