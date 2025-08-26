# frozen_string_literal: true

class CrispUpdatePeopleDataJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  queue_as :default

  def perform(user)
    user_data = Crisp::UserDataBuilder.new(user).build_data

    Crisp::APIService.new.update_people_data(
      email: user.email,
      body: { data: user_data }
    )
  end
end
