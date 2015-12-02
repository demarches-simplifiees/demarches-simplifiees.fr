class DossiersDecorator < Draper::CollectionDecorator
  delegate :current_page, :per_page, :offset, :total_entries, :total_pages

  def active_class_a_traiter page
    'active' if page == 'a_traiter'
  end

  def active_class_en_attente page
    'active' if page == 'en_attente'
  end

  def active_class_termine page
    'active' if page == 'termine'
  end
end
