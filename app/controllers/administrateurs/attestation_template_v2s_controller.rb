module Administrateurs
  class AttestationTemplateV2sController < ActionController::Base
    def show
      render layout: 'attestation'
    end
  end
end
