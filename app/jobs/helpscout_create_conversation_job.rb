# frozen_string_literal: true

class HelpscoutCreateConversationJob < ApplicationJob
  queue_as :default

  class FileNotScannedYetError < StandardError
  end

  retry_on FileNotScannedYetError, wait: :exponentially_longer, attempts: 10

  def perform(blob_id: nil, **args)
    if blob_id.present?
      blob = ActiveStorage::Blob.find(blob_id)
      raise FileNotScannedYetError if blob.virus_scanner.pending?

      blob = nil unless blob.virus_scanner.safe?
    end

    Helpscout::FormAdapter.new(**args, blob:).send_form
  end
end
