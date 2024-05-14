# frozen_string_literal: true

class InvitesController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :store_user_location!, only: [:show]

  def create
    email = params[:invite_email]&.downcase
    @dossier = current_user.dossiers.visible_by_user.find(params[:dossier_id])
    invite = Invite.create(
      dossier: @dossier,
      user: User.find_by(email: email),
      email: email,
      message: params[:invite_message],
      email_sender: current_user.email
    )

    if invite.valid?
      # The notification is sent through an after commit hook in order to avoir concurrency issues
      flash.notice = t('views.invites.create.success', email: invite.email)
    else
      flash.alert = invite.errors.full_messages
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: helpers.url_for_dossier(@dossier)) }
      format.turbo_stream
    end
  end

  def show
    if user_signed_in?
      erase_user_location!
      dossier = Dossier.joins(:invites)
        .find_by!(invites: { email: current_user.email, id: params[:id] })

      redirect_to helpers.url_for_dossier(dossier)
    elsif params[:email].present? && !User.find_by(email: params[:email])
      redirect_to new_user_registration_path(user: { email: params[:email] })
    else
      authenticate_user!
    end
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to dossiers_path
  end

  def destroy
    invite = Invite.find_by(id: params[:id], dossier: current_user.dossiers.visible_by_user)

    if invite.present?
      @dossier = invite.dossier
      invite.destroy!
      flash.notice = t('views.invites.destroy.success', email: invite.email)
    else
      flash.alert = t('views.invites.destroy.error')
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: @dossier.present? ? helpers.url_for_dossier(@dossier) : root_url) }
      format.turbo_stream
    end
  end

  private

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def erase_user_location!
    clear_stored_location_for(:user)
  end
end
