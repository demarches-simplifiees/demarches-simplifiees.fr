class AutoArchiveProcedureWorker
  include Sidekiq::Worker

  def perform(*args)
    Procedure.publiees.where("auto_archive_on <= ?", Date.today).each do |procedure|
      procedure.dossiers.state_en_construction.each do |dossier|
        dossier.received!
      end

      procedure.archive
    end
  end
end
