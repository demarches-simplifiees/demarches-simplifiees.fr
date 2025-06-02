# frozen_string_literal: true

class Instructeurs::ActivateAccountFormComponent < ApplicationComponent
  attr_reader :user
  def initialize(user:)
    @user = user
  end
end
