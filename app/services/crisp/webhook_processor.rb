# frozen_string_literal: true

module Crisp
  class WebhookProcessor
    include Dry::Monads[:result]

    # IMPORTANT: Outgoing traffic is restricted in production: never call the Crisp API from a webhook request, use a job!
    def initialize(params)
      @params = params
      @email = extract_email_from_params
      @session_id = params.dig(:data, :session_id)
    end

    def process
      return unless processable_event?

      CrispUpdatePeopleDataJob.perform_later(session_id, email)
    end

    private

    attr_reader :params, :session_id, :email

    def processable_event?
      params[:event] == "message:send" && params.dig(:data, :from) == "user"
    end

    def extract_email_from_params
      # conversations from chat does not use an email as user id
      maybe_email = params.dig(:data, :user, :user_id)
      maybe_email&.include?("@") ? maybe_email : nil
    end
  end
end
