# frozen_string_literal: true

class ErrorsController < ApplicationController
  def nav_bar_profile = try_nav_bar_profile_from_referrer

  def not_found
    render(status: 404)
  end
end
