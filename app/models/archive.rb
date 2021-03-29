# == Schema Information
#
# Table name: archives
#
#  id           :bigint           not null, primary key
#  content_type :string           not null
#  month        :date
#  status       :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Archive < ApplicationRecord
  include AASM

  RETENTION_DURATION = 1.week

  has_and_belongs_to_many :groupe_instructeurs

  has_one_attached :file

  scope :stale, -> { where('updated_at < ?', (Time.zone.now - RETENTION_DURATION)) }
  scope :for_groupe_instructeur, -> (groupe_instructeur) {
    joins(:archives_groupe_instructeurs)
      .where(
        archives_groupe_instructeurs: { groupe_instructeur: groupe_instructeur }
      )
  }

  enum content_type: {
    everything: 'everything',
    monthly:    'monthly'
  }

  enum status: {
    pending: 'pending',
    generated: 'generated'
  }

  aasm whiny_persistence: true, column: :status, enum: true do
    state :pending, initial: true
    state :generated

    event :make_available do
      transitions from: :pending, to: :generated
    end
  end

  def available?
    status == 'generated' && file.attached?
  end

  def filename(procedure)
    if content_type == 'everything'
      "procedure-#{procedure.id}.zip"
    else
      "procedure-#{procedure.id}-mois-#{I18n.l(month, format: '%Y-%m')}.zip"
    end
  end
end
