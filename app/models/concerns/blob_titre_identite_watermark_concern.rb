# Request a watermark on blobs attached to a `Champs::TitreIdentiteChamp`
# after the virus scan has run.
#
# We're using a class extension here, but we could as well have a periodic
# job that watermarks relevant attachments.
#
# The `after_commit` hook is triggered, among other cases, when
# the analyzer or virus scan updates the blob metadata. When both the analyzer
# and the virus scan have run, it is now safe to start the watermarking,
# without  risking to replace the picture while it is being scanned in a
# concurrent job.
module BlobTitreIdentiteWatermarkConcern
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_watermark_job
  end

  def watermark_pending?
    watermark_required? && !watermark_done?
  end

  private

  def watermark_required?
    attachments.any? { |attachment| attachment.record.class.name == 'Champs::TitreIdentiteChamp' }
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
