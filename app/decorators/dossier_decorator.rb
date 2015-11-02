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
      when 'submitted'
        'Soumis'
      when 'replied'
        'Répondu'
      when 'updated'
        'Mis à jour'
      when 'validated'
        'Validé'
      when 'submit_validated'
        'Déposé'
      when 'processed'
        'Traité'
      else
        fail 'State not valid'
    end
  end
end
