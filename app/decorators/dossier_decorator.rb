class DossierDecorator < Draper::Decorator
  include Rails.application.routes.url_helpers

  delegate :current_page, :limit_value, :total_pages
  delegate_all

  def first_creation
    created_at.localtime.strftime('%d/%m/%Y %H:%M')
  end

  def last_update
    updated_at.localtime.strftime('%d/%m/%Y %H:%M')
  end

  def display_state
    DossierDecorator.case_state_fr state
  end

  def url(gestionnaire_signed_in)
    if brouillon?
      users_dossier_description_path(id)
    else
      users_dossier_recapitulatif_path(id)
    end
  end

  def self.case_state_fr state=self.state
    h.t("activerecord.attributes.dossier.state.#{state}")
  end
end
