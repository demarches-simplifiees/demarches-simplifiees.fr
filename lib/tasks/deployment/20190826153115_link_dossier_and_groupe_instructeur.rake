namespace :after_party do
  desc 'Deployment task: link_dossier_and_groupe_instructeur'
  task link_dossier_and_groupe_instructeur: :environment do
    sql = <<~SQL
      UPDATE dossiers AS d1 SET groupe_instructeur_id = g.id
      FROM groupe_instructeurs AS g
      WHERE g.procedure_id = d1.procedure_id
        and d1.groupe_instructeur_id is null;
    SQL

    ActiveRecord::Base.connection.execute(sql)

    AfterParty::TaskRecord.create version: '20190826153115'
  end
end
