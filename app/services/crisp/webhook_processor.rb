# frozen_string_literal: true

module Crisp
  class WebhookProcessor
    include Dry::Monads[:result]

    def initialize(params)
      @params = params
      @email = extract_email_from_params
    end

    def process
      return unless processable_event?

      @email = fetch_email_from_session if email.blank?

      return if user.blank?

      CrispUpdatePeopleDataJob.perform_later(user)
    end

    private

    attr_reader :params, :email

    def processable_event?
      params[:event] == "message:send" && params.dig(:data, :from) == "user"
    end

    def extract_email_from_params
      # conversations from chat does not use an email as user id
      maybe_email = params.dig(:data, :user, :user_id)
      maybe_email&.include?("@") ? maybe_email : nil
    end

    def user
      @user ||= User.find_by(email:)
    end

    def fetch_email_from_session
      session_id = params.dig(:data, :session_id)

      result = Crisp::APIService.new.get_conversation_meta(session_id:)
      case result
      in Success(data: {email:})
        email
      in Failure(reason:)
        fail reason
      end
    end
  end
end
