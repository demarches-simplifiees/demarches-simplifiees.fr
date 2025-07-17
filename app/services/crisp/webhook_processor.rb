# frozen_string_literal: true

module Crisp
  class WebhookProcessor
    def initialize(params)
      @params = params
      @email = extract_email
    end

    def process
      return unless processable_event?
      return if user.blank?

      user_data = UserDataBuilder.new(user).build_data

      APIService.new.update_people_data(
        email: email,
        body: { data: user_data }
      )
    end

    private

    attr_reader :params, :email

    def processable_event?
      params[:event] == "message:send"
    end

    def extract_email
      params.dig(:data, :user, :user_id)
    end

    def user
      @user ||= User.find_by(email:)
    end
  end
end
