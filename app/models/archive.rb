# == Schema Information
#
# Table name: archives
#
#  id             :bigint           not null, primary key
#  job_status     :string           not null
#  key            :text             not null
#  month          :date
#  time_span_type :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Archive < ApplicationRecord
  include TransientModelsWithPurgeableJobConcern

  RETENTION_DURATION = 4.days
  MAX_DUREE_GENERATION = 16.hours
  MAX_SIZE = 100.gigabytes

  has_and_belongs_to_many :groupe_instructeurs

  has_one_attached :file

  scope :for_groupe_instructeur, -> (groupe_instructeur) {
    joins(:archives_groupe_instructeurs)
      .where(
        archives_groupe_instructeurs: { groupe_instructeur: groupe_instructeur }
      )
  }

  enum time_span_type: {
    everything: 'everything',
    monthly:    'monthly'
  }

  def filename(procedure)
    if time_span_type == 'everything'
      "procedure-#{procedure.id}.zip"
    else
      "procedure-#{procedure.id}-mois-#{I18n.l(month, format: '%Y-%m')}.zip"
    end
  end

  def self.find_or_create_archive(time_span_type, month, groupe_instructeurs)
    create_with(groupe_instructeurs: groupe_instructeurs)
      .create_or_find_by(time_span_type: time_span_type, month: month, key: generate_cache_key(groupe_instructeurs))
  end

  private

  def self.generate_cache_key(groupe_instructeurs)
    groupe_instructeurs.map(&:id).sort.join('-')
  end
end
