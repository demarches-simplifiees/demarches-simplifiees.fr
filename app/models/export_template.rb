class ExportTemplate < ApplicationRecord
  include TagsSubstitutionConcern

  belongs_to :instructeur
  belongs_to :groupe_instructeur
  has_one :procedure, through: :groupe_instructeur

  DOSSIER_STATE = Dossier.states.fetch(:en_construction)

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

  def content_for_pj_id(stable_id)
    content_for_stable_id = content["pjs"].find { _1.symbolize_keys[:stable_id] == stable_id.to_s }
    content_for_stable_id.symbolize_keys.fetch(:path)
  end

  def pj_and_path(dossier, pj, index: 0, row_index: nil)
    [
      pj,
      path(dossier, pj, index, row_index)
    ]
  end

  def tiptap_convert(dossier, param)
    if content[param]["content"]&.first["content"]
      render_attributes_for(content[param])
    end
  end

  def tiptap_convert_pj(dossier, pj_stable_id)
    if content_for_pj_id(pj_stable_id)["content"]&.first["content"]
      render_attributes_for(content_for_pj_id(pj_stable_id))
    end
  end

  def render_attributes_for(content_for, dossier=sample_dossier)
    tiptap = TiptapService.new
    used_tags = tiptap.used_tags_and_libelle_for(content_for.deep_symbolize_keys)
    substitutions = tags_substitutions(used_tags, dossier, escape: false)
    tiptap.to_path(content_for.deep_symbolize_keys, substitutions)
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

  def sample_dossier
    procedure.dossiers.first
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

  def path(dossier, pj, index, row_index)
    if pj.name == 'pdf_export_for_instructeur'
      return export_path(dossier)
    end

    dir_path = case pj.record_type
    when 'Dossier'
      'dossier'
    when 'Commentaire'
      'messagerie'
    when 'Avis'
      'avis'
    else
      # for pj
      return pj_path(dossier, pj, index, row_index)
    end

    File.join(folder(dossier), dir_path, pj.filename.to_s)
  end

  def pj_path(dossier, pj, index, row_index)
    type_de_champ_id = dossier.champs.find(pj.record_id).type_de_champ_id
    stable_id = TypeDeChamp.find(type_de_champ_id).stable_id
    tiptap_pj = content["pjs"].find { |pj| pj["stable_id"] == stable_id.to_s }
    if tiptap_pj
      File.join(folder(dossier), tiptap_convert_pj(dossier, stable_id) + suffix(pj, index, row_index))
    else
      File.join(folder(dossier), "erreur_renommage", pj.filename.to_s)
    end
  end

  def suffix(pj, index, row_index)
    suffix = "-#{index + 1}"
    suffix += "-#{row_index + 1}" if row_index
    suffix += pj.filename.extension_with_delimiter
  end
end
