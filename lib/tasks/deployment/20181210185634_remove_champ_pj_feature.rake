namespace :after_party do
  desc 'Deployment task: remove_champ_pj_feature'
  task remove_champ_pj_feature: :environment do
    rake_puts "Running deploy task 'remove_champ_pj_feature'"

    Administrateur.find_by_sql(
      <<~SQL
        SELECT administrateurs.*
        FROM administrateurs, lateral jsonb_each(features)
        WHERE key = 'champ_pj'
        GROUP BY id
      SQL
    ).each do |admin|
      admin.features.delete('champ_pj')
      admin.save
    end

    AfterParty::TaskRecord.create version: '20181210185634'
  end
end
