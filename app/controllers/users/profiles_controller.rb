class Users::ProfilesController < ApplicationController
  def show
    @user = User.find(params[:user_id]).decorate
  end

  def edit
    @user = current_user
  end

  def update
    current_user.update(profile_params)
    redirect_to user_profile_url(current_user)
  end

  def destroy
    current_user.update(picture: nil, remove_picture: true)
    redirect_to edit_users_profile_url
  end

  private

  def profile_params
    params.require(:user)
      .permit(:gender, :given_name, :family_name, :entreprise_siret, :birthdate, :picture)
  end
end
