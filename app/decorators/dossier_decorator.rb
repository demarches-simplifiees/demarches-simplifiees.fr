class DossierDecorator < Draper::Decorator
  delegate :current_page, :limit_value, :total_pages
  delegate_all

  def first_creation
    created_at.strftime('%d/%m/%Y %H:%M')
  end

  def last_update
    updated_at.strftime('%d/%m/%Y %H:%M')
  end
end
