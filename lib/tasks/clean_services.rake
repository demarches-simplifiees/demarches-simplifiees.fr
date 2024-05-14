# frozen_string_literal: true

namespace :service do
  desc 'remove service without procedure'
  task remove_orphans: :environment do
    puts "Destroying services without procedure..."
    Service.joins('LEFT OUTER JOIN "procedures" ON "procedures"."service_id" = "services"."id"')
      .where(procedures: { id: nil })
      .destroy_all
    puts "Services without procedure destroyed"
  end

  desc 'email admins with published procedures with service without siret'
  task email_no_siret: :environment do
    admins = Administrateur.joins(:administrateurs_procedures).where(administrateurs_procedures: { procedure: Procedure.publiees.joins(:service).where(service: { siret: nil }) })
    progress = ProgressReport.new(admins.count)

    admins.each do |admin|
      AdministrateurMailer.notify_service_without_siret(admin.email).deliver_later
      progress.inc
    end
  end
end
