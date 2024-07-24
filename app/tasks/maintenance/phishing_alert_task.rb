# frozen_string_literal: true

module Maintenance
  class PhishingAlertTask < MaintenanceTasks::Task
    csv_collection

    def process(row)
      email = row["Identity"].delete('"')
      user = User.find_by(email: email)

      # if the user has been updated less than a minute ago
      # we guess that the user has already been processed
      # in another row of the csv
      return if user.nil? || 1.minute.ago < user.updated_at

      user.update(password: SecureRandom.hex)

      PhishingAlertMailer.notify(user).deliver_later
    end
  end
end
