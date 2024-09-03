# frozen_string_literal: true

class SuperAdminMailer < ApplicationMailer
  def dolist_report(to, csv_path)
    attachments["dolist_report.csv"] = File.read(csv_path)

    mail(to: to, subject: "Dolist report", body: "Ci-joint le rapport d'emails récents envoyés via Dolist.")
  end

  def self.critical_email?(action_name)
    false
  end
end
