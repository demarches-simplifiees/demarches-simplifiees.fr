class DossierDecorator < Draper::Decorator
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

  def state_color_class
    return 'text-danger' if a_traiter?
    return 'text-info' if en_attente?
    return 'text-success' if termine?
  end
end
