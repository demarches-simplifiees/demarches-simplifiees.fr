class ExportTemplate < ApplicationRecord
  include TagsSubstitutionConcern

  belongs_to :groupe_instructeur
  has_one :procedure, through: :groupe_instructeur
  has_many :exports, dependent: :nullify
  validates_with ExportTemplateValidator

  DOSSIER_STATE = Dossier.states.fetch(:en_construction)
  FORMAT_DATE = "%Y-%m-%d"

  def set_default_values
    content["default_dossier_directory"] = tiptap_json("dossier-")
    content["pdf_name"] = tiptap_json("export_")

    content["pjs"] = []
    procedure.exportables_pieces_jointes.each do |pj|
      content["pjs"] << { "stable_id" => pj.stable_id.to_s, "path" => tiptap_json("#{pj.libelle.parameterize}-") }
    end
  end

  def tiptap_default_dossier_directory=(body)
    self.content["default_dossier_directory"] = JSON.parse(body)
  end

  def tiptap_default_dossier_directory
    tiptap_content("default_dossier_directory")
  end

  def tiptap_pdf_name=(body)
    self.content["pdf_name"] = JSON.parse(body)
  end

  def tiptap_pdf_name
    tiptap_content("pdf_name")
  end

  def content_for_pj(pj)
    content_for_pj_id(pj.stable_id)&.to_json
  end

  def assign_pj_names(pj_params)
    self.content["pjs"] = []
    pj_params.each do |pj_param|
      self.content["pjs"] << { stable_id: pj_param[0].delete_prefix("tiptap_pj_"), path: JSON.parse(pj_param[1]) }
    end
  end

  def attachment_and_path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    [
      attachment,
      path(dossier, attachment, index:, row_index:, champ:)
    ]
  end

  def tiptap_convert(dossier, param)
    if content[param]["content"]&.first&.[]("content")
      render_attributes_for(content[param], dossier)
    end
  end

  def tiptap_convert_pj(dossier, pj_stable_id, attachment = nil)
    if content_for_pj_id(pj_stable_id)["content"]&.first&.[]("content")
      render_attributes_for(content_for_pj_id(pj_stable_id), dossier, attachment)
    end
  end

  def render_attributes_for(content_for, dossier, attachment = nil)
    used_tags = TiptapService.used_tags_and_libelle_for(content_for.deep_symbolize_keys)
    substitutions = tags_substitutions(used_tags, dossier, escape: false, memoize: true)
    substitutions['original-filename'] = attachment.filename.base if attachment
    TiptapService.new.to_path(content_for.deep_symbolize_keys, substitutions)
  end

  def specific_tags
    tags_categorized.slice(:individual, :etablissement, :dossier).values.flatten
  end

  def tags_for_pj
    specific_tags.push({
      libelle: 'nom original du fichier',
      id: 'original-filename',
      maybe_null: false
    })
  end

  private

  def tiptap_content(key)
    content[key]&.to_json
  end

  def tiptap_json(prefix)
    {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "text" => prefix, "type" => "text" }, { "type" => "mention", "attrs" => DOSSIER_ID_TAG.stringify_keys }] }
      ]
    }
  end

  def content_for_pj_id(stable_id)
    content_for_stable_id = content["pjs"].find { _1.symbolize_keys[:stable_id] == stable_id.to_s }
    content_for_stable_id.symbolize_keys.fetch(:path)
  end

  def folder(dossier)
    render_attributes_for(content["default_dossier_directory"], dossier)
  end

  def export_path(dossier)
    File.join(folder(dossier), export_filename(dossier))
  end

  def export_filename(dossier)
    "#{render_attributes_for(content["pdf_name"], dossier)}.pdf"
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
    tiptap_pj = content["pjs"].find { |pj| pj["stable_id"] == stable_id.to_s }
    if tiptap_pj
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
end
