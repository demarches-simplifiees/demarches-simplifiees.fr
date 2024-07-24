# frozen_string_literal: true

class HelpscoutCreateConversationJob < ApplicationJob
  queue_as :default

  class FileNotScannedYetError < StandardError
  end

  retry_on FileNotScannedYetError, wait: :exponentially_longer, attempts: 10

  attr_reader :api

  def perform(blob_id: nil, **params)
    if blob_id.present?
      blob = ActiveStorage::Blob.find(blob_id)
      raise FileNotScannedYetError if blob.virus_scanner.pending?

      blob = nil unless blob.virus_scanner.safe?
    end

    @api = Helpscout::API.new

    create_conversation(params, blob)
  end

  private

  def create_conversation(params, blob)
    response = api.create_conversation(
      params[:email],
      params[:subject],
      params[:text],
      blob
    )

    if response.success?
      conversation_id = response.headers['Resource-ID']

      if params[:phone].present?
        api.add_phone_number(params[:email], params[:phone])
      end

      api.add_tags(conversation_id, params[:tags])
    else
      fail "Error while creating conversation: #{response.response_code} '#{response.body}'"
    end
  end
end
