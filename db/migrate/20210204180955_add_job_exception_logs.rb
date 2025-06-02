# frozen_string_literal: true

class AddJobExceptionLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :dossiers, :api_entreprise_job_exceptions, :string, array: true
    add_column :champs, :fetch_external_data_exceptions, :string, array: true
  end
end
