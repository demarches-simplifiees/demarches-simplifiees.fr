class BackofficeController < ApplicationController
  include SmartListing::Helper::ControllerExtensions
  helper  SmartListing::Helper

  before_action :authenticate_gestionnaire!, only: [:invitations]

  def index
    if !gestionnaire_signed_in?
      redirect_to(controller: '/gestionnaires/sessions', action: :new)
    else
      redirect_to(:backoffice_dossiers)
    end
  end

  def invitations
    pending_avis = current_gestionnaire.avis.without_answer.includes(dossier: [:procedure]).by_latest
    @pending_avis = smart_listing_create :pending_avis,
                         pending_avis,
                         partial: 'backoffice/dossiers/list_invitations',
                         array: true

    avis_with_answer = current_gestionnaire.avis.with_answer.includes(dossier: [:procedure]).by_latest
    @avis_with_answer = smart_listing_create :avis_with_answer,
                        avis_with_answer,
                        partial: 'backoffice/dossiers/list_invitations',
                        array: true
  end
end
