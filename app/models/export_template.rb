# frozen_string_literal: true

class ExportTemplate < ApplicationRecord
  include TagsSubstitutionConcern

  self.ignored_columns += ["content"]

  belongs_to :groupe_instructeur
  has_one :procedure, through: :groupe_instructeur
  has_many :exports, dependent: :nullify

  enum kind: { zip: "zip" }, _prefix: :template

  attribute :dossier_folder, :export_item
  attribute :export_pdf, :export_item
  attribute :pjs, :export_item, array: true

  before_validation :ensure_pjs_are_legit

  validates_with ExportTemplateValidator

  DOSSIER_STATE = Dossier.states.fetch(:en_construction)

  # when a pj has been added to a revision, it will not be present in the previous pjs
  # a default value is provided.
  def pj(tdc)
    pjs.find { _1.stable_id == tdc.stable_id } || ExportItem.default_pj(tdc)
  end

  def self.default(name: nil, kind: 'zip', groupe_instructeur:)
    dossier_folder = ExportItem.default(prefix: 'dossier')
    export_pdf = ExportItem.default(prefix: 'export')
    pjs = groupe_instructeur.procedure.exportables_pieces_jointes.map { |tdc| ExportItem.default_pj(tdc) }

    new(name:, kind:, groupe_instructeur:, dossier_folder:, export_pdf:, pjs:)
  end

  def tags
    tags_categorized.slice(:individual, :etablissement, :dossier).values.flatten
  end

  def pj_tags
    tags.push(
      libelle: 'nom original du fichier',
      id: 'original-filename'
    )
  end

  def attachment_path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    file_path = if attachment.name == 'pdf_export_for_instructeur'
      export_pdf.path(dossier, attachment:)
    elsif attachment.record_type == 'Champ' && pj(champ.type_de_champ).enabled?
      pj(champ.type_de_champ).path(dossier, attachment:, index:, row_index:)
    else
      nil
    end

    File.join(dossier_folder.path(dossier), file_path) if file_path.present?
  end

  private

  def ensure_pjs_are_legit
    legitimate_pj_stable_ids = procedure.exportables_pieces_jointes_for_all_versions.map(&:stable_id)

    self.pjs = pjs.filter { _1.stable_id.in?(legitimate_pj_stable_ids) }
  end
end
