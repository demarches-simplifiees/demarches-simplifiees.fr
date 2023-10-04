class ReleaseNote < ApplicationRecord
  has_rich_text :body

  CATEGORIES = [
    'administrateur',
    'instructeur',
    'expert',
    'usager',
    'api'
  ]

  validates :categories, presence: true, inclusion: { in: CATEGORIES }
  validates :body, presence: true

  scope :published, -> { where(published: true, released_on: ..Date.current) }
  scope :for_categories, -> (categories) { where("categories && ARRAY[?]::varchar[]", categories) }
end
