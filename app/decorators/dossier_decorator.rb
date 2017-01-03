class DossierDecorator < Draper::Decorator
  delegate :current_page, :per_page, :offset, :total_entries, :total_pages
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

  def self.case_state_fr state=self.state
    h.t("activerecord.attributes.dossier.state.#{state}")
  end
end
