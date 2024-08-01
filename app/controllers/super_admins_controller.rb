# frozen_string_literal: true

class SuperAdminsController < ApplicationController
  before_action :authenticate_super_admin!

  def edit_otp
  end

  def enable_otp
    current_super_admin.enable_otp!
    @qrcode = generate_qr_code
    sign_out :super_admin
  end

  protected

  def authenticate_super_admin!
    if !super_admin_signed_in?
      redirect_to root_path
    end
  end

  private

  def generate_qr_code
    issuer = 'DSManager'

    if Rails.env.development?
      issuer += " (local)"
    elsif helpers.staging?
      issuer += " (dev)"
    end

    label = "#{issuer}:#{current_super_admin.email}"
    RQRCode::QRCode.new(current_super_admin.otp_provisioning_uri(label, issuer: issuer))
  end
end
