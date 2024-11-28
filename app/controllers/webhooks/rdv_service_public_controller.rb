# frozen_string_literal: true

class Webhooks::RdvServicePublicController < ApplicationController
  before_action :verify_signature

  def create
    return unless params[:meta][:event].in?(['updated', 'deleted']) && params[:meta][:model] == 'Rdv'

    rdv = Rdv.find_by(rdv_service_public_id: params[:data][:id])

    rdv.update!(params.require(:data).permit(:status, :starts_at))

    render json: { message: 'OK' }
  end

  private

  def verify_signature
    # TODO: Implement signature verification
  end
end
