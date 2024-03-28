# frozen_string_literal: true

class ErrorsController < ApplicationController
  def nav_bar_profile = try_nav_bar_profile_from_referrer

  def not_found
    render(status: 404)
  end

  def internal_server_error
    render file: Rails.public_path.join('500.html'), layout: false, status: :internal_server_error
  end
end
