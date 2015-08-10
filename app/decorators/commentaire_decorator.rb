class CommentaireDecorator < Draper::Decorator
  delegate_all

  def created_at_fr
    created_at.to_datetime.strftime("%d/%m/%Y - %H:%M")
  rescue
    'dd/mm/YYYY - HH:MM'
  end

end
