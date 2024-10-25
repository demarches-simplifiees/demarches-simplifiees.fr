# frozen_string_literal: true

class RdvServicePublic::OauthController < ApplicationController
  before_action :authenticate_instructeur!

  def callback
    user_info = request.env['omniauth.auth']

    rdv_connection_attributes = {
      expires_at: Time.zone.at(user_info.credentials.expires_at),
      access_token: user_info.credentials.token,
      refresh_token: user_info.credentials.refresh_token
    }

    if current_instructeur.rdv_connection.present?
      current_instructeur.rdv_connection.update!(rdv_connection_attributes)
    else
      current_instructeur.create_rdv_connection!(rdv_connection_attributes)
    end

    redirect_path = request.env['omniauth.origin'] || root_path

    redirect_to redirect_path, notice: "Votre compte RDV Service Public a été connecté avec succès"
  end
end
