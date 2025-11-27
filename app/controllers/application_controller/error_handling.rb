# frozen_string_literal: true

module ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::InvalidAuthenticityToken do
      render file: Rails.public_path.join('403.html'), layout: false, status: :forbidden
    end
  end
end
