class Users::ProfilesController < ApplicationController
  def show
    @profile = Profile.find_or_initialize_by(user_id: params[:user_id]).decorate
  end

  def edit
    @profile = (current_user.profile || current_user.build_profile).decorate
  end

  def update
    if profile = current_user.profile
      profile.update(profile_params)
    else
      current_user.create_profile(profile_params)
    end
    redirect_to user_profile_url(current_user)
  end

  def destroy
    if profile = current_user.profile
      profile.remove_picture!

      # If using #save CarrierWave will try to delete the file *twice* and fail
      # hard, since the file can't be found the second time. We thus erase the
      # column in database directly, which avoids the callback to be fired a
      # second time.
      profile.update_column(:picture, nil)
    end
    redirect_to edit_users_profile_url
  end

  private

  def profile_params
    params.require(:profile)
      .permit(:gender, :given_name, :family_name, :entreprise_siret, :birthdate, :picture)
  end
end
