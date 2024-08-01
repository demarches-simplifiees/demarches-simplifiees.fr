# frozen_string_literal: true

class SamlIdpController < ActionController::Base
  include SamlIdp::Controller

  def new
    if validate_saml_request
      render template: 'saml_idp/new'
    else
      head :forbidden
    end
  end

  def show
    render xml: SamlIdp.metadata.signed
  end

  def create
    if validate_saml_request
      if super_admin_signed_in?
        @saml_response = idp_make_saml_response(current_super_admin)
        render template: 'saml_idp/saml_post', layout: false
      else
        redirect_to root_path, alert: t("errors.messages.saml_not_authorized")
      end
    else
      head :forbidden
    end
  end

  private

  def idp_make_saml_response(super_admin)
    encode_response super_admin, encryption: {
      cert: saml_request.service_provider.cert,
      block_encryption: 'aes256-cbc',
      key_transport: 'rsa-oaep-mgf1p'
    }
  end
end
