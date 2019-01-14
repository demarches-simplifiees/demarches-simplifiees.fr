module Devise
  # Useful helpers additions to Devise::Controllers::StoreLocation
  module StoreLocationExtension
    # Delete the url stored in the session for the given scope.
    def clear_stored_location_for(resource_or_scope)
      session_key = send(:stored_location_key_for, resource_or_scope)
      session.delete(session_key)
    end
  end
end
