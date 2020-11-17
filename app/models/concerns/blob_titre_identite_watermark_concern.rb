module BlobTitreIdentiteWatermarkConcern
  extend ActiveSupport::Concern

  included do
    after_update_commit :enqueue_watermark_job
  end

  private

  def titre_identite?
    attachments.find { |attachment| attachment.record.class.name == 'Champs::TitreIdentiteChamp' }
  end

  def watermarked?
    metadata[:watermark]
  end

  def enqueue_watermark_job
    if titre_identite? && !watermarked? && analyzed? && virus_scanner.done?
      TitreIdentiteWatermarkJob.perform_later(self)
    end
  end
end
