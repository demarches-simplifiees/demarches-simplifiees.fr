# == Schema Information
#
# Table name: exports
#
#  id         :bigint           not null, primary key
#  format     :string           not null
#  key        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Export < ApplicationRecord
  MAX_DUREE_CONSERVATION_EXPORT = 1.hour

  enum format: {
    csv: 'csv',
    ods: 'ods',
    xlsx: 'xlsx'
  }

  has_and_belongs_to_many :groupe_instructeurs

  has_one_attached :file

  validates :format, :groupe_instructeurs, :key, presence: true

  scope :stale, -> { where('exports.updated_at < ?', (Time.zone.now - MAX_DUREE_CONSERVATION_EXPORT)) }

  after_create_commit :compute_async

  def compute_async
    ExportJob.perform_later(self)
  end

  def compute
    file.attach(
      io: io,
      filename: filename,
      content_type: content_type,
      # We generate the exports ourselves, so they are safe
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
  end

  def ready?
    file.attached?
  end

  def self.find_or_create_export(format, groupe_instructeurs)
    create_with(groupe_instructeurs: groupe_instructeurs)
      .create_or_find_by(format: format, key: generate_cache_key(groupe_instructeurs))
  end

  def self.find_for_format_and_groupe_instructeurs(format, groupe_instructeurs)
    find_by(format: format, key: generate_cache_key(groupe_instructeurs))
  end

  def self.generate_cache_key(groupe_instructeurs)
    groupe_instructeurs.map(&:id).sort.join('-')
  end

  private

  def filename
    procedure_identifier = procedure.path || "procedure-#{procedure.id}"
    "dossiers_#{procedure_identifier}_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M')}.#{format}"
  end

  def io
    dossiers = Dossier.where(groupe_instructeur: groupe_instructeurs)
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
