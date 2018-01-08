class DossiersDecorator < Draper::CollectionDecorator
  delegate :current_page, :limit_value, :total_pages
end
