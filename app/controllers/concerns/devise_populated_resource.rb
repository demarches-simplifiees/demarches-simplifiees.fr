# frozen_string_literal: true

module DevisePopulatedResource
  extend ActiveSupport::Concern

  # During a GET /password/edit, the resource is a brand new object.
  # This method gives access to the actual resource record (if available), complete with email, relationships, etc.
  #
  # If the resource can't be found (typically because the reset password token has expired),
  # returns the default blank record.
  def populated_resource
    resource_class.with_reset_password_token(resource.reset_password_token) || resource
  end

  included do
    helper_method :populated_resource
  end
end
