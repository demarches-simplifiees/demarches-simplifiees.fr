# == Schema Information
#
# Table name: exports
#
#  id                              :bigint           not null, primary key
#  format                          :string           not null
#  job_status                      :string           default("pending"), not null
#  key                             :text             not null
#  procedure_presentation_snapshot :jsonb
#  statut                          :string           default("tous")
#  time_span_type                  :string           default("everything"), not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  procedure_presentation_id       :bigint
#
class Export < ApplicationRecord
  include TransientModelsWithPurgeableJobConcern

  MAX_DUREE_CONSERVATION_EXPORT = 32.hours
  MAX_DUREE_GENERATION = 16.hours

  enum format: {
    csv: 'csv',
    ods: 'ods',
    xlsx: 'xlsx',
    zip: 'zip'
  }, _prefix: true

  enum time_span_type: {
    everything: 'everything',
    monthly:    'monthly'
  }

  enum statut: {
    'a-suivre': 'a-suivre',
    suivis: 'suivis',
    traites: 'traites',
    tous: 'tous',
    supprimes_recemment: 'supprimes_recemment',
    archives: 'archives',
    expirant: 'expirant'
  }

  has_and_belongs_to_many :groupe_instructeurs
  belongs_to :procedure_presentation, optional: true

  has_one_attached :file

  validates :format, :groupe_instructeurs, :key, presence: true

  after_create_commit :compute_async

  FORMATS_WITH_TIME_SPAN = [:xlsx, :ods, :csv].flat_map do |format|
    [{ format: format, time_span_type: 'everything' }]
  end
  FORMATS = [:xlsx, :ods, :csv, :zip].map do |format|
    { format: format }
  end

  def compute_async
    ExportJob.perform_later(self)
  end

  def compute
    load_snapshot!

    file.attach(blob)
  end

  def since
    time_span_type == Export.time_span_types.fetch(:monthly) ? 30.days.ago : nil
  end

  def old?
    updated_at < 20.minutes.ago || filters_changed?
  end

  def filters_changed?
    procedure_presentation&.snapshot != procedure_presentation_snapshot
  end

  def filtered?
    procedure_presentation_id.present?
  end

  def self.find_or_create_export(format, groupe_instructeurs, time_span_type: time_span_types.fetch(:everything), statut: statuts.fetch(:tous), procedure_presentation: nil)
    create_with(groupe_instructeurs: groupe_instructeurs, procedure_presentation: procedure_presentation, procedure_presentation_snapshot: procedure_presentation&.snapshot)
      .includes(:procedure_presentation)
      .create_or_find_by(format: format,
        time_span_type: time_span_type,
        statut: statut,
        key: generate_cache_key(groupe_instructeurs.map(&:id), procedure_presentation&.id))
  end

  def self.find_for_groupe_instructeurs(groupe_instructeurs_ids, procedure_presentation)
    exports = if procedure_presentation.present?
      where(key: generate_cache_key(groupe_instructeurs_ids))
        .or(where(key: generate_cache_key(groupe_instructeurs_ids, procedure_presentation.id)))
    else
      where(key: generate_cache_key(groupe_instructeurs_ids))
    end
    filtered, not_filtered = exports.partition(&:filtered?)

    {
      xlsx: {
        time_span_type: not_filtered.filter(&:format_xlsx?).index_by(&:time_span_type),
        statut: filtered.filter(&:format_xlsx?).index_by(&:statut)
      },
      ods: {
        time_span_type: not_filtered.filter(&:format_ods?).index_by(&:time_span_type),
        statut: filtered.filter(&:format_ods?).index_by(&:statut)
      },
      csv: {
        time_span_type: not_filtered.filter(&:format_csv?).index_by(&:time_span_type),
        statut: filtered.filter(&:format_csv?).index_by(&:statut)
      },
      zip: {
        time_span_type: {},
        statut: filtered.filter(&:format_zip?).index_by(&:statut)
      }
    }
  end

  def self.generate_cache_key(groupe_instructeurs_ids, procedure_presentation_id = nil)
    if procedure_presentation_id.present?
      "#{groupe_instructeurs_ids.sort.join('-')}--#{procedure_presentation_id}"
    else
      groupe_instructeurs_ids.sort.join('-')
    end
  end

  def count
    if procedure_presentation_id.present?
      dossiers_for_export.size
    end
  end

  private

  def load_snapshot!
    if procedure_presentation_snapshot.present?
      procedure_presentation.attributes = procedure_presentation_snapshot
    end
  end

  def dossiers_for_export
    @dossiers_for_export ||= begin
      dossiers = Dossier.where(groupe_instructeur: groupe_instructeurs)

      if since.present?
        dossiers.visible_by_administration.where('dossiers.depose_at > ?', since)
      elsif procedure_presentation.present?
        filtered_sorted_ids = procedure_presentation
          .filtered_sorted_ids(dossiers, statut)

        dossiers.where(id: filtered_sorted_ids)
      else
        dossiers.visible_by_administration
      end
    end
  end

  def blob
    service = ProcedureExportService.new(procedure, dossiers_for_export)

    case format.to_sym
    when :csv
      service.to_csv
    when :xlsx
      service.to_xlsx
    when :ods
      service.to_ods
    when :zip
      service.to_zip
    end
  end

  def procedure
    groupe_instructeurs.first.procedure
  end
end
