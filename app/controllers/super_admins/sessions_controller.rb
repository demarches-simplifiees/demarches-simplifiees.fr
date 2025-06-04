# frozen_string_literal: true

class SuperAdmins::SessionsController < Devise::SessionsController
  def nav_bar_profile = :superadmin
end
