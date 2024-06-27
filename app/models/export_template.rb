class ExportTemplate < ApplicationRecord
  include TagsSubstitutionConcern

  belongs_to :groupe_instructeur
  has_one :procedure, through: :groupe_instructeur
  has_many :exports, dependent: :nullify
  validates_with ExportTemplateValidator

  store_accessor :content, :default_dossier_directory, :pdf_name, :pjs

  DOSSIER_STATE = Dossier.states.fetch(:en_construction)
  FORMAT_DATE = "%Y-%m-%d"

  def pj(stable_id)
    pjs.find { _1['stable_id'] == stable_id.to_s }&.fetch('path')
  end

  def set_default_values
    self.default_dossier_directory = path_with_dossier_id_suffix("dossier-")
    self.pdf_name = path_with_dossier_id_suffix("export_")

    self.pjs = procedure.exportables_pieces_jointes.map do |pj|
      { "stable_id" => pj.stable_id.to_s, "path" => path_with_dossier_id_suffix("#{pj.libelle.parameterize}-") }
    end
  end

  def tags
    tags_categorized.slice(:individual, :etablissement, :dossier).values.flatten
  end

  def pj_tags
    tags.push({
      libelle: 'nom original du fichier',
      id: 'original-filename',
      maybe_null: false
    })
  end

  def folder_path(dossier)
    render_attributes_for(default_dossier_directory, dossier)
  end

  # pdf_export_path ?
  def dossier_pdf_path(dossier)
    "#{render_attributes_for(pdf_name, dossier)}.pdf"
  end

  def pj_path(dossier, pj_stable_id, attachment = nil)
    render_attributes_for(pj(pj_stable_id), dossier, attachment)
  end

  def attachment_path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    return File.join(folder_path(dossier), dossier_pdf_path(dossier)) if attachment.name == 'pdf_export_for_instructeur'

    filename = attachment.filename.to_s

    dir_path = case attachment.record_type
    when 'Dossier'
      ['dossier', filename]
    when 'Commentaire'
      ['messagerie', filename]
    when 'Avis'
      ['avis', filename]
    when 'Attestation', 'Etablissement'
      ['pieces_justificatives', filename]
    else
      [pj_path(dossier, champ.stable_id, attachment) + suffix(attachment, index, row_index)] if pj(champ.stable_id)
    end

    File.join(folder_path(dossier), File.join(dir_path)) if dir_path.present?
  end

  private

  def path_with_dossier_id_suffix(prefix)
    {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "text" => prefix, "type" => "text" }, { "type" => "mention", "attrs" => DOSSIER_ID_TAG.slice(:id, :label).stringify_keys }] }
      ]
    }
  end

  def suffix(attachment, index, row_index)
    suffix = "-#{index + 1}"
    suffix += "-#{row_index + 1}" if row_index.present?

    suffix + attachment.filename.extension_with_delimiter
  end

  def render_attributes_for(content_for, dossier, attachment = nil)
    used_tags = TiptapService.used_tags_and_libelle_for(content_for.deep_symbolize_keys)
    substitutions = tags_substitutions(used_tags, dossier, escape: false, memoize: true)
    substitutions['original-filename'] = attachment.filename.base if attachment
    TiptapService.new.to_path(content_for.deep_symbolize_keys, substitutions)
  end
end
