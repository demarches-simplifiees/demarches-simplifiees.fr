# frozen_string_literal: true

module ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::InvalidAuthenticityToken do
      # When some browsers (like Safari) re-open a previously closed tab, they attempts
      # to reload the page – even if it is a POST request. But in that case, they don’t
      # sends any of the cookies and we don’t report this error.
      #
      # There are dozens of these "errors" every day,
      # we only log them to detect massive attacks or global errors
      # without having thousands reports.
      if request.cookies.any? && rand(10) == 0
        log_invalid_authenticity_token_error
      end

      raise # propagate the exception up, to render the default exception page
    end
  end

  private

  def log_invalid_authenticity_token_error
    Sentry.with_scope do |temp_scope|
      tags = {
        action: "#{self.class.name}#{action_name}",
      }
      temp_scope.set_tags(tags)
      Sentry.capture_message("ActionController::InvalidAuthenticityToken")
    end
  end
end
