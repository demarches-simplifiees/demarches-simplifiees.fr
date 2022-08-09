class SamlIdpController < ActionController::Base
  include SamlIdp::Controller

  before_action :validate_saml_request

  def new
    if super_admin_signed_in?
      @saml_response = encode_SAMLResponse(current_super_admin.email, saml_attributes)
      Rails.logger.debug "SAML ACS URL: #{@saml_acs_url}"
      Rails.logger.debug "SAML RESPONSE: #{@saml_response}"
      render :template => "saml_idp/idp/saml_post", :layout => false
    else
      redirect_to root_path, alert: t("errors.messages.saml_not_authorized")
    end
  end

  def metadata
    render layout: false, content_type: "application/xml", formats: :xml
  end

  private

  def saml_attributes
    admin_attributes = %[<saml:AttributeStatement><saml:Attribute NameFormat="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"><saml:AttributeValue>#{current_super_admin.email}</saml:AttributeValue></saml:Attribute></saml:AttributeStatement>]
    {
      issuer_uri: saml_auth_url,
      attributes_provider: admin_attributes
    }
  end
end
