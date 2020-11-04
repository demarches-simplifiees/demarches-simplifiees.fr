class AdministrationsController < ApplicationController
  before_action :authenticate_administration!

  def edit_otp
  end

  def enable_otp
    current_administration.enable_otp!
    @qrcode = generate_qr_code
    sign_out :administration
  end

  protected

  def authenticate_administration!
    if !administration_signed_in?
      redirect_to root_path
    end
  end

  private

  def generate_qr_code
    issuer = 'DSManager'
    label = "#{issuer}:#{current_administration.email}"
    RQRCode::QRCode.new(current_administration.otp_provisioning_uri(label, issuer: issuer))
  end
end
