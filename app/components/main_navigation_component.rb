class MainNavigationComponent < ApplicationComponent

  attr_reader :current_user
  def initialize(current_user:)
    @current_user = current_user
  end

  def show_annonces?
    current_user.instructeur? || current_user.administrateur?
  end

  def create_annonce?
    controller.super_admin_signed_in?
  end


end