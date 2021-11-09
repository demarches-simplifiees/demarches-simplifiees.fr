module DevisePopulatedResource
  extend ActiveSupport::Concern

  # During a GET /password/edit, the resource is a brand new object.
  # This method gives access to the actual resource record, complete with email, relationships, etc.
  def populated_resource
    resource_class.with_reset_password_token(resource.reset_password_token)
  end

  included do
    helper_method :populated_resource
  end
end
