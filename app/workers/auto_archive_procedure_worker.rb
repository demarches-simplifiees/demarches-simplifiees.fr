class AutoArchiveProcedureWorker
  include Sidekiq::Worker

  def perform(*args)
    Procedure.not_archived.where("auto_archive_on <= ?", Date.today).each do |procedure|
      procedure.dossiers.state_en_construction.update_all(state: :received)

      procedure.update_attributes!(archived: true)
    end
  end
end
