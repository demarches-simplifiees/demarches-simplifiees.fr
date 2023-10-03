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
end
