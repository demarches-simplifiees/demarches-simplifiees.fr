# frozen_string_literal: true

class ReleaseNote < ApplicationRecord
  has_rich_text :body

  CATEGORIES = [
    'administrateur',
    'instructeur',
    'expert',
    'usager',
    'api',
  ]

  validates :categories, presence: true, inclusion: { in: CATEGORIES }
  validates :body, presence: true

  scope :published, -> { where(published: true, released_on: ..Date.current) }
  scope :for_categories, -> (categories) { where("categories && ARRAY[?]::varchar[]", categories) }

  def self.default_categories_for_role(role, instance = nil)
    case role
    when :administrateur
      ['administrateur', 'usager', instance.api_tokens.exists? ? 'api' : nil]
    when :instructeur
      ['instructeur', instance.user.expert? ? 'expert' : nil]
    when :expert
      ['expert', instance.user.instructeur? ? 'instructeur' : nil]
    else
      ['usager']
    end
  end

  def self.most_recent_announce_date_for_categories(categories)
    published.for_categories(categories).maximum(:released_on)
  end
end
