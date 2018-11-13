namespace :'2018_10_30_admin_has_gestionnaire' do
  task run: :environment do
    admin_without_gestionnaire_ids = Administrateur
      .find_by_sql('SELECT administrateurs.id FROM administrateurs LEFT OUTER JOIN gestionnaires ON gestionnaires.email = administrateurs.email WHERE gestionnaires.email IS NULL')
      .pluck(:id)

    admin_without_gestionnaire_ids.each do |admin_id|
      admin = Administrateur.find(admin_id)
      g = Gestionnaire.new
      g.email = admin.email
      g.encrypted_password = admin.encrypted_password
      g.save(validate: false)
    end
  end
end
