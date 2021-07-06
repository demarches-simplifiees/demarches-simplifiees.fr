module ApplicationController::ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::InvalidAuthenticityToken do
      if cookies.count == 0
        # When some browsers (like Safari) re-open a previously closed tab, they attempts
        # to reload the page – even if it is a POST request. But in that case, they don’t
        # sends any of the cookies.
        #
        # Ignore this error.
        render plain: "Les cookies doivent être activés pour utiliser #{APPLICATION_NAME}.", status: 403
      else
        log_invalid_authenticity_token_error
        raise # propagate the exception up, to render the default exception page
      end
    end
  end

  def log_invalid_authenticity_token_error
    Sentry.with_scope do |temp_scope|
      tags = {
        action: "#{self.class.name}#{action_name}"
      }
      temp_scope.set_tags(tags)
      Sentry.capture_message("ActionController::InvalidAuthenticityToken")
    end
  end
end
