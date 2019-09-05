namespace :after_party do
  desc 'Deployment task: link_dossier_and_groupe_instructeur'
  task link_dossier_and_groupe_instructeur: :environment do
    sql = <<~SQL
      UPDATE dossiers SET groupe_instructeur_id = groupe_instructeurs.id
      FROM dossiers AS d1 INNER JOIN groupe_instructeurs ON groupe_instructeurs.procedure_id = d1.procedure_id
      WHERE dossiers.id = d1.id;
    SQL

    ActiveRecord::Base.connection.execute(sql)

    AfterParty::TaskRecord.create version: '20190826153115'
  end
end
