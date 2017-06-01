class AutoArchiveProcedureWorker
  include Sidekiq::Worker

  def perform(*args)
    procedures_to_archive = Procedure.not_archived.where("auto_archive_on <= ?", Date.today)

    procedures_to_archive.each do |p|
      p.dossiers.state_en_construction.update_all(state: :received)
    end

    procedures_to_archive.update_all(archived: true, auto_archive_on: nil)

  end
end
