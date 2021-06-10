class AddAPIParticulierJobExceptionToDossier < ActiveRecord::Migration[6.0]
  def change
    add_column :dossiers, :api_particulier_job_exceptions, :string, array: true
  end
end
