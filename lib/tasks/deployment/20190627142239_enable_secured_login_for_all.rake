namespace :after_party do
  desc 'Deployment task: enable_secured_login_for_all'
  task enable_secured_login_for_all: :environment do
    Gestionnaire.update_all(features: { "enable_email_login_token": true })

    AfterParty::TaskRecord.create version: '20190627142239'
  end
end
