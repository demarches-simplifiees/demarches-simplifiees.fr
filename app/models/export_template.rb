class ExportTemplate < ApplicationRecord
  include TagsSubstitutionConcern

  belongs_to :groupe_instructeur
  has_one :procedure, through: :groupe_instructeur
  has_many :exports, dependent: :nullify
  validates_with ExportTemplateValidator

  store_accessor :content, :default_dossier_directory, :pdf_name, :pjs

  DOSSIER_STATE = Dossier.states.fetch(:en_construction)
  FORMAT_DATE = "%Y-%m-%d"

  def set_default_values
    self.default_dossier_directory = path_with_dossier_id_suffix("dossier-")
    self.pdf_name = path_with_dossier_id_suffix("export_")

    self.pjs = procedure.exportables_pieces_jointes.map do |pj|
      { "stable_id" => pj.stable_id.to_s, "path" => path_with_dossier_id_suffix("#{pj.libelle.parameterize}-") }
    end
  end

  def attachment_and_path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    [
      attachment,
      path(dossier, attachment, index:, row_index:, champ:)
    ]
  end

  def pj_path(stable_id)
    pjs.find { _1['stable_id'] == stable_id.to_s }&.fetch('path')
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

  def export_filename(dossier)
    "#{render_attributes_for(pdf_name, dossier)}.pdf"
  end

  def folder(dossier)
    render_attributes_for(default_dossier_directory, dossier)
  end

  def tiptap_convert_pj(dossier, pj_stable_id, attachment = nil)
    render_attributes_for(pj_path(pj_stable_id), dossier, attachment)
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

  def path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    filename = attachment.filename.to_s

    dir_path = case [attachment.record_type, attachment.name]
    in _, 'pdf_export_for_instructeur'
      [export_filename(dossier)]
    in 'Dossier', _
      ['dossier', filename]
    in 'Commentaire', _
      ['messagerie', filename]
    in 'Avis', _
      ['avis', filename]
    in 'Attestation' | 'Etablissement', _
      ['pieces_justificatives', filename]
    else
      [tiptap_convert_pj(dossier, champ.stable_id, attachment) + suffix(attachment, index, row_index)] if pj_path(champ.stable_id)
    end

    File.join(folder(dossier), File.join(dir_path)) if dir_path.present?
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
