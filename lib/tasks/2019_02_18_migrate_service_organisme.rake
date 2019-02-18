namespace :after_party do
  desc 'Deployment task:  migrate service organisme'
  task migrate_service_organisme: :environment do
    table = {
      'commune': 'collectivite_territoriale',
      'departement': 'collectivite_territoriale',
      'region': 'collectivite_territoriale',
      'prefecture': 'service_deconcentre_de_l_etat'
    }

    table.each do |(old_name, new_name)|
      Service.where(type_organisme: old_name).update_all(type_organisme: new_name)
    end

    AfterParty::TaskRecord.create version: '20190201121252'
  end
end
