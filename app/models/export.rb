# frozen_string_literal: true

# TODO: add migration to store sorted and filtered columns
# then change snapshot to extract those columns and store it
# finally, adapt the load_snapshot! method to load those columns

class Export < ApplicationRecord
  include TransientModelsWithPurgeableJobConcern

  MAX_DUREE_CONSERVATION_EXPORT = 32.hours
  MAX_DUREE_GENERATION = 16.hours

  enum format: {
    csv: 'csv',
    ods: 'ods',
    xlsx: 'xlsx',
    zip: 'zip',
    json: 'json'
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
    supprimes: 'supprimes',
    archives: 'archives',
    expirant: 'expirant'
  }

  has_and_belongs_to_many :groupe_instructeurs
  belongs_to :procedure_presentation, optional: true
  belongs_to :instructeur, optional: true
  belongs_to :user_profile, polymorphic: true, optional: true
  belongs_to :export_template, optional: true

  has_one_attached :file

  validates :format, :groupe_instructeurs, :key, presence: true

  scope :ante_chronological, -> { order(updated_at: :desc) }

  after_create_commit :compute_async

  FORMATS_WITH_TIME_SPAN = [:xlsx, :ods, :csv].flat_map do |format|
    [{ format: format, time_span_type: 'everything' }]
  end
  FORMATS = [:xlsx, :ods, :csv, :zip, :json].map do |format|
    { format: format }
  end

  def compute_async
    ExportJob.perform_later(self)
  end

  def compute
    self.dossiers_count = dossiers_for_export.count
    load_snapshot!

    file.attach(blob.signed_id) # attaching a blob directly might run identify/virus scanner and wipe it
  end

  def since
    time_span_type == Export.time_span_types.fetch(:monthly) ? 30.days.ago : nil
  end

  def filtered?
    procedure_presentation_id.present?
  end

  def self.find_or_create_fresh_export(format, groupe_instructeurs, user_profile, time_span_type: time_span_types.fetch(:everything), statut: statuts.fetch(:tous), procedure_presentation: nil, export_template: nil)
    attributes = {
      format:,
      export_template:,
      time_span_type:,
      statut:,
      key: generate_cache_key(groupe_instructeurs.map(&:id), procedure_presentation)
    }

    recent_export = pending
      .or(generated.where(updated_at: (5.minutes.ago)..))
      .includes(:procedure_presentation)
      .find_by(attributes)

    return recent_export if recent_export.present?

    create!(**attributes, groupe_instructeurs:,
                          user_profile:,
                          procedure_presentation:,
                          procedure_presentation_snapshot: procedure_presentation&.snapshot)
  end

  def self.for_groupe_instructeurs(groupe_instructeurs_ids)
    joins(:groupe_instructeurs).where(groupe_instructeurs: groupe_instructeurs_ids).distinct(:id)
  end

  def self.by_key(groupe_instructeurs_ids, procedure_presentation)
    where(key: [
      generate_cache_key(groupe_instructeurs_ids),
      generate_cache_key(groupe_instructeurs_ids, procedure_presentation)
    ])
  end

  def self.generate_cache_key(groupe_instructeurs_ids, procedure_presentation = nil)
    if procedure_presentation.present?
      [
        groupe_instructeurs_ids.sort.join('-'),
        procedure_presentation.id,
        Digest::MD5.hexdigest(procedure_presentation.snapshot.slice(:filters, :sort).to_s)
      ].join('--')
    else
      groupe_instructeurs_ids.sort.join('-')
    end
  end

  def count
    return dossiers_count if !dossiers_count.nil? # export generated
    return dossiers_for_export.count if procedure_presentation_id.present?

    nil
  end

  def procedure
    groupe_instructeurs.first.procedure
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
    service = ProcedureExportService.new(procedure, dossiers_for_export, user_profile, export_template)

    case format.to_sym
    when :csv
      service.to_csv
    when :xlsx
      service.to_xlsx
    when :ods
      service.to_ods
    when :zip
      service.to_zip
    when :json
      service.to_geo_json
    end
  end
end
