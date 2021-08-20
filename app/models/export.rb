# == Schema Information
#
# Table name: exports
#
#  id             :bigint           not null, primary key
#  format         :string           not null
#  key            :text             not null
#  time_span_type :string           default("everything"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Export < ApplicationRecord
  MAX_DUREE_CONSERVATION_EXPORT = 3.hours

  enum format: {
    csv: 'csv',
    ods: 'ods',
    xlsx: 'xlsx'
  }

  enum time_span_type: {
    everything: 'everything',
    monthly:    'monthly'
  }

  has_and_belongs_to_many :groupe_instructeurs

  has_one_attached :file

  validates :format, :groupe_instructeurs, :key, presence: true

  scope :stale, -> { where('exports.updated_at < ?', (Time.zone.now - MAX_DUREE_CONSERVATION_EXPORT)) }

  after_create_commit :compute_async

  FORMATS = [:xlsx, :ods, :csv].flat_map do |format|
    Export.time_span_types.values.map do |time_span_type|
      [format, time_span_type]
    end
  end

  def compute_async
    ExportJob.perform_later(self)
  end

  def compute
    file.attach(
      io: io(since: since),
      filename: filename,
      content_type: content_type,
      # We generate the exports ourselves, so they are safe
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
  end

  def since
    time_span_type == Export.time_span_types.fetch(:monthly) ? 30.days.ago : nil
  end

  def ready?
    file.attached?
  end

  def old?
    updated_at < 20.minutes.ago
  end

  def self.find_or_create_export(format, time_span_type, groupe_instructeurs)
    create_with(groupe_instructeurs: groupe_instructeurs)
      .create_or_find_by(format: format,
        time_span_type: time_span_type,
        key: generate_cache_key(groupe_instructeurs.map(&:id)))
  end

  def self.find_for_groupe_instructeurs(groupe_instructeurs_ids)
    exports = where(key: generate_cache_key(groupe_instructeurs_ids))

    [:xlsx, :csv, :ods].map do |format|
      [
        format,
        Export.time_span_types.values.map do |time_span_type|
          [time_span_type, exports.find { |export| export.format == format.to_s && export.time_span_type == time_span_type }]
        end.filter { |(_, export)| export.present? }.to_h
      ]
    end.filter { |(_, exports)| exports.present? }.to_h
  end

  def self.generate_cache_key(groupe_instructeurs_ids)
    groupe_instructeurs_ids.sort.join('-')
  end

  private

  def filename
    procedure_identifier = procedure.path || "procedure-#{procedure.id}"
    "dossiers_#{procedure_identifier}_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M')}.#{format}"
  end

  def io(since: nil)
    dossiers = Dossier.where(groupe_instructeur: groupe_instructeurs)
    if since.present?
      dossiers = dossiers.where('dossiers.en_construction_at > ?', since)
    end
    service = ProcedureExportService.new(procedure, dossiers)

    case format.to_sym
    when :csv
      StringIO.new(service.to_csv)
    when :xlsx
      StringIO.new(service.to_xlsx)
    when :ods
      StringIO.new(service.to_ods)
    end
  end

  def content_type
    case format.to_sym
    when :csv
      'text/csv'
    when :xlsx
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    when :ods
      'application/vnd.oasis.opendocument.spreadsheet'
    end
  end

  def procedure
    groupe_instructeurs.first.procedure
  end
end
