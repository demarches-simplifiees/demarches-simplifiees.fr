# frozen_string_literal: true

class CrispUpdatePeopleDataJob < ApplicationJob
  include Dry::Monads[:result]

  discard_on ActiveRecord::RecordNotFound

  queue_as :default

  def perform(session_id, email)
    email ||= fetch_email_from_session(session_id)
    user = User.find_by!(email:)

    user_data = Crisp::UserDataBuilder.new(user).build_data

    result = Crisp::APIService.new.update_people_data(
      email: user.email,
      body: { data: user_data }
    )

    case result
    in Success
      # NOOP
    in Failure(reason:)
      fail reason
    end
  end

  private

  def fetch_email_from_session(session_id)
    result = Crisp::APIService.new.get_conversation_meta(session_id:)
    case result
    in Success(data: { email: })
      email
    in Failure(reason:)
      fail reason
    end
  end
end
