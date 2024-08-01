# frozen_string_literal: true

class HelpscoutCreateConversationJob < ApplicationJob
  queue_as :default

  class FileNotScannedYetError < StandardError
  end

  retry_on FileNotScannedYetError, wait: :exponentially_longer, attempts: 10

  attr_reader :contact_form
  attr_reader :api

  def perform(contact_form)
    @contact_form = contact_form

    if contact_form.piece_jointe.attached?
      raise FileNotScannedYetError if contact_form.piece_jointe.virus_scanner.pending?
    end

    @api = Helpscout::API.new

    create_conversation

    contact_form.delete
  end

  private

  def create_conversation
    response = api.create_conversation(
      contact_form.email.presence || contact_form.user.email,
      contact_form.subject,
      contact_form.text,
      safe_blob
    )

    if response.success?
      conversation_id = response.headers['Resource-ID']

      if contact_form.phone.present?
        api.add_phone_number(contact_form.email, contact_form.phone)
      end

      api.add_tags(conversation_id, contact_form.tags)
    else
      fail "Error while creating conversation: #{response.response_code} '#{response.body}'"
    end
  end

  def safe_blob
    return if !contact_form.piece_jointe.virus_scanner&.safe?

    contact_form.piece_jointe
  end
end
