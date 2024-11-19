# frozen_string_literal: true

class AccountDropdownComponent < ViewComponent::Base
  attr_reader :dossier
  attr_reader :nav_bar_profile

  delegate :current_email, :color_by_role, :multiple_devise_profile_connect?,
           :user_signed_in?, :instructeur_signed_in?, :expert_signed_in?,
           :administrateur_signed_in?, :gestionnaire_signed_in?, :super_admin_signed_in?,
           to: :helpers

  def initialize(dossier:, nav_bar_profile:)
    @dossier = dossier
    @nav_bar_profile = nav_bar_profile
  end

  def france_connected?
    dossier&.france_connected_with_one_identity?
  end

  def show_profile_badge?
    nav_bar_profile != :guest
  end
end
