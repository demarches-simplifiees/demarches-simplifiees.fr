module BlobTitreIdentiteWatermarkConcern
  extend ActiveSupport::Concern

  included do
    after_update_commit :enqueue_watermark_job
  end

  def watermark_pending?
    watermark_required? && !watermark_done?
  end

  private

  def watermark_required?
    attachments.find { |attachment| attachment.record.class.name == 'Champs::TitreIdentiteChamp' }
  end

  def watermark_done?
    metadata[:watermark]
  end

  def enqueue_watermark_job
    if analyzed? && virus_scanner.done? && watermark_pending?
      TitreIdentiteWatermarkJob.perform_later(self)
    end
  end
end
