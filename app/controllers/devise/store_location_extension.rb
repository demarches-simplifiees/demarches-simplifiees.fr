module Devise
  # Useful helpers additions to Devise::Controllers::StoreLocation
  module StoreLocationExtension
    # A variant of `stored_location_key_for` which doesn't delete the stored path.
    def get_stored_location_for(resource_or_scope)
      location = stored_location_for(resource_or_scope)
      if location
        store_location_for(resource_or_scope, location)
      end
      location
    end

    # Delete the url stored in the session for the given scope.
    def clear_stored_location_for(resource_or_scope)
      session_key = send(:stored_location_key_for, resource_or_scope)
      session.delete(session_key)
    end
  end
end
