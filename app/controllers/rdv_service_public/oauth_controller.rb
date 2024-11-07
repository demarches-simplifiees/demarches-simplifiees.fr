# frozen_string_literal: true

class RdvServicePublic::OauthController < ApplicationController
  def callback
    rdv_connection_attributes = {
      access_token: "fake access_token",
      refresh_token: "fake refresh_token",
      expires_at: 3.days.from_now

    }

    if current_administrateur.instructeur.rdv_connection.present?
      current_administrateur.instructeur.rdv_connection.update!(rdv_connection_attributes)
    else
      current_administrateur.instructeur.create_rdv_connection!(rdv_connection_attributes)
    end

    redirect_to params[:next], notice: "RDV Service Public connecté avec succès"
  end
end
