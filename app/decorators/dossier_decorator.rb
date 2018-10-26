class DossierDecorator < Draper::Decorator
  include Rails.application.routes.url_helpers

  delegate :current_page, :limit_value, :total_pages
  delegate_all

  def first_creation
    created_at.strftime('%d/%m/%Y %H:%M')
  end

  def last_update
    updated_at.strftime('%d/%m/%Y %H:%M')
  end

  def display_state
    DossierDecorator.case_state_fr state
  end

  def self.case_state_fr(state = self.state)
    h.t("activerecord.attributes.dossier.state.#{state}")
  end
end
