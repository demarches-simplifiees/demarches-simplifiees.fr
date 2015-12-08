class DossierDecorator < Draper::Decorator
  delegate :current_page, :per_page, :offset, :total_entries, :total_pages
  delegate_all

  def date_fr
    date_previsionnelle.to_date.strftime('%d/%m/%Y')
  rescue
    'dd/mm/YYYY'
  end

  def last_update
    updated_at.localtime.strftime('%d/%m/%Y %H:%M')
  end

  def state_fr
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
    case state
      when 'draft'
        'Brouillon'
      when 'initiated'
        'Soumis'
      when 'replied'
        'Répondu'
      when 'updated'
        'Mis à jour'
      when 'validated'
        'Validé'
      when 'submitted'
        'Déposé'
      when 'closed'
        'Traité'
      else
        fail 'State not valid'
    end
  end
end
