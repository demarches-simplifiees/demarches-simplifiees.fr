# frozen_string_literal: true

module Maintenance
  class T20250414backfillUserIdInProConnectInformationTask < MaintenanceTasks::Task
    # This task backfills the user_id column in the agent_connect_informations table
    # It sets the user_id based on the associated instructeur's user_id
    # This is part of the migration from using instructeur_id to user_id for ProConnect authentication

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # This task will run automatically on first deployment
    # It's important to run this after the migration that adds the user_id column
    run_on_first_deploy

    # Returns all ProConnectInformation records that don't have a user_id set yet
    def collection
      ProConnectInformation.where(user_id: nil)
    end

    # For each record, sets the user_id to the instructeur's user_id
    # This creates the link between ProConnectInformation and User
    def process(pro_connect_information)
      pro_connect_information.update!(
        user_id: pro_connect_information.instructeur.user_id
      )
    end

    # Returns the count of records that need to be processed
    # Used for progress tracking
    def count
      collection.count
    end
  end
end
