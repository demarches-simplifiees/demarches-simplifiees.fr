class DossierDecorator < Draper::Decorator
  delegate :current_page, :per_page, :offset, :total_entries, :total_pages
  delegate_all

  def display_date
    date_previsionnelle.localtime.strftime('%d/%m/%Y')
  rescue
    'dd/mm/YYYY'
  end

  def first_creation
    created_at.localtime.strftime('%d/%m/%Y %H:%M')
  end

  def last_update
    updated_at.localtime.strftime('%d/%m/%Y %H:%M')
  end

  def display_state
    DossierDecorator.case_state_fr state
  end

  def class_qp_active
    'qp' if procedure.module_api_carto.quartiers_prioritaires
  end

  def state_color_class
    return 'text-danger' if waiting_for_gestionnaire?
    return 'text-info' if waiting_for_user?
    return 'text-success' if termine?
  end

  def self.case_state_fr state=self.state
    h.t("activerecord.attributes.dossier.state.#{state}")
  end
end
