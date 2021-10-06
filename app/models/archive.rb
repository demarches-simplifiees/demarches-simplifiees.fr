# == Schema Information
#
# Table name: archives
#
#  id             :bigint           not null, primary key
#  end_day        :date
#  key            :text             not null
#  month          :date
#  start_day      :date
#  status         :string           not null
#  time_span_type :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Archive < ApplicationRecord
  include AASM

  RETENTION_DURATION = 1.week
  MAX_CUSTOM_ARCHIVE_WEIGHT = 4.gigabytes

  has_and_belongs_to_many :groupe_instructeurs

  has_one_attached :file

  scope :stale, -> { where('updated_at < ?', (Time.zone.now - RETENTION_DURATION)) }
  scope :for_groupe_instructeur, -> (groupe_instructeur) {
    joins(:archives_groupe_instructeurs)
      .where(
        archives_groupe_instructeurs: { groupe_instructeur: groupe_instructeur }
      )
  }

  enum time_span_type: {
    everything: 'everything',
    monthly:    'monthly',
    custom: 'custom'
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
    case time_span_type
    when 'everything'
      "procedure-#{procedure.id}.zip"
    when 'monthly'
      "procedure-#{procedure.id}-mois-#{I18n.l(month, format: '%Y-%m')}.zip"
    when 'custom'
      "procedure-#{procedure.id}-#{I18n.l(start_day, format: '%Y-%m-%d')}-#{I18n.l(end_day, format: '%Y-%m-%d')}.zip"
    end
  end

  def self.find_or_create_archive(time_span_type, period, groupe_instructeurs)
    case time_span_type
    when 'everything'
      create_with(groupe_instructeurs: groupe_instructeurs)
        .create_or_find_by(time_span_type: time_span_type, key: generate_cache_key(groupe_instructeurs))
    when 'monthly'
      create_with(groupe_instructeurs: groupe_instructeurs)
        .create_or_find_by(time_span_type: time_span_type, month: period[:month], key: generate_cache_key(groupe_instructeurs))
    when 'custom'
      create_with(groupe_instructeurs: groupe_instructeurs)
        .create_or_find_by(time_span_type: time_span_type, start_day: period[:start_day], end_day: period[:end_day], key: generate_cache_key(groupe_instructeurs))
    end
  end

  def self.by_period(procedure, groupe_instructeurs)
    archives = for_groupe_instructeur(groupe_instructeurs)
    Traitement.count_dossiers_termines_by_month(groupe_instructeurs).to_a.flat_map do |count_by_month|
      if procedure.estimate_weight(count_by_month['count']) <= Archive::MAX_CUSTOM_ARCHIVE_WEIGHT
        {
          month: count_by_month['month'],
          matching_archive: archives.find { |archive| archive.time_span_type == 'monthly' && archive.month == count_by_month['month'] },
          count: count_by_month['count']
        }
      else
        Traitement.count_dossiers_termines_with_archive_size_limit(procedure, groupe_instructeurs, count_by_month['month']).to_a.flat_map do |count_by_month|
          {
            month: count_by_month[:month],
            start_day: count_by_month[:start_day],
            end_day: count_by_month[:end_day],
            matching_archive: archives.find { |archive| archive.time_span_type == 'custom' && archive.start_day == count_by_month[:start_day] && archive.end_day == count_by_month[:end_day] },
            count: count_by_month[:count]
          }
        end
      end
    end
  end

  private

  def self.generate_cache_key(groupe_instructeurs)
    groupe_instructeurs.map(&:id).sort.join('-')
  end
end
