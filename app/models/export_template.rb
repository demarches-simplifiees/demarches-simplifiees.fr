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
    content["default_dossier_directory"] = tiptap_json("dossier-")
    content["pdf_name"] = tiptap_json("export_")

    content["pjs"] = procedure.exportables_pieces_jointes.map do |pj|
      { "stable_id" => pj.stable_id.to_s, "path" => tiptap_json("#{pj.libelle.parameterize}-") }
    end
  end

  def attachment_and_path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    [
      attachment,
      path(dossier, attachment, index:, row_index:, champ:)
    ]
  end

  def tiptap_convert_pj(dossier, pj_stable_id, attachment = nil)
    render_attributes_for(pj_path(pj_stable_id), dossier, attachment)
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

  private

  def tiptap_json(prefix)
    {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "text" => prefix, "type" => "text" }, { "type" => "mention", "attrs" => DOSSIER_ID_TAG.stringify_keys }] }
      ]
    }
  end

  def export_path(dossier)
    File.join(folder(dossier), export_filename(dossier))
  end

  def path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    if attachment.name == 'pdf_export_for_instructeur'
      return export_path(dossier)
    end

    dir_path = case attachment.record_type
    when 'Dossier'
      'dossier'
    when 'Commentaire'
      'messagerie'
    when 'Avis'
      'avis'
    when 'Attestation', 'Etablissement'
      'pieces_justificatives'
    else
      # for attachment
      return attachment_path(dossier, attachment, index, row_index, champ)
    end

    File.join(folder(dossier), dir_path, attachment.filename.to_s)
  end

  def attachment_path(dossier, attachment, index, row_index, champ)
    stable_id = champ.stable_id

    if pj_path(stable_id)
      File.join(folder(dossier), tiptap_convert_pj(dossier, stable_id, attachment) + suffix(attachment, index, row_index))
    else
      File.join(folder(dossier), "erreur_renommage", attachment.filename.to_s)
    end
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
