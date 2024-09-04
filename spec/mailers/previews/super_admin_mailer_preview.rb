# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/super_admin_mailer
class SuperAdminMailerPreview < ActionMailer::Preview
  def dolist_report
    SuperAdminMailer.dolist_report("you@beta.gouv.fr", Rails.root.join("spec/fixtures/files/groupe_avec_caracteres_speciaux.csv"))
  end
end
