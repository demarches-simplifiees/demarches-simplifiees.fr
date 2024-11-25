# frozen_string_literal: true

module Maintenance
  # This task backfills the email_verified_at field for confirmed users
  # as a bug fixed by https://github.com/demarches-simplifiees/demarches-simplifiees.fr/pull/11074
  # produced unverified confirmed users.
  class VerifyConfirmedUsersTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    no_collection

    attribute :verifying_date, :string
    attribute :correction_period, :integer

    def process
      email_verified_at = if verifying_date.present?
        Time.zone.parse(verifying_date)
      else
        Time.zone.parse('25/11/2024')
      end

      created_at = if correction_period.present?
        correction_period.months.ago..
      else
        4.months.ago..
      end

      User
        .where.not(confirmed_at: nil)
        .where(email_verified_at: nil)
        .where(created_at:)
        .where(instructeur: { id: nil }) # instructeur is eager loaded
        .where.missing(:expert)
        .update_all(email_verified_at:)
    end
  end
end
