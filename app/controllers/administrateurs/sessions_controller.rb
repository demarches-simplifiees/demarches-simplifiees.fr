class Administrateurs::SessionsController < Devise::SessionsController

  def new
    @administrateur = Administrateur.new
  end

  def create
    super
  end

  def after_sign_in_path_for(resource)
    # stored_location_for(resource) ||
    admin_path
  end
end
