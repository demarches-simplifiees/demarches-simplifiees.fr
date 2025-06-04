# frozen_string_literal: true

module NavBarProfileConcern
  extend ActiveSupport::Concern

  included do
    # Override this method on controller basis for more precise context or custom logic
    def nav_bar_profile
    end

    def fallback_nav_bar_profile
      return :guest if current_user.blank?

      nav_bar_profile_from_referrer || default_nav_bar_profile_for_user
    end

    private

    # Shared controllers (search, errors, release notes…) don't have specific context
    # Simple attempt to try to re-use the profile from the previous page
    # so user does'not feel lost.
    def nav_bar_profile_from_referrer
      # detect context from referer, simple (no detection when refreshing the page)
      params = Rails.application.routes.recognize_path(request&.referer)

      controller_class = "#{params[:controller].camelize}Controller".safe_constantize
      return if controller_class.nil?

      controller_instance = controller_class.new
      controller_instance.try(:nav_bar_profile)
    end

    # Fallback for shared controllers from user account
    # to the more relevant profile.
    def default_nav_bar_profile_for_user
      return :gestionnaire if current_user.gestionnaire?
      return :administrateur if current_user.administrateur?
      return :instructeur if current_user.instructeur?
      return :expert if current_user.expert?

      :user
    end
  end
end
