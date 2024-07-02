class ExportTemplate < ApplicationRecord
  include TagsSubstitutionConcern
  include ActiveSupport::Inflector

  belongs_to :groupe_instructeur
  has_one :procedure, through: :groupe_instructeur
  has_many :exports, dependent: :nullify
  validates_with ExportTemplateValidator

  store_accessor :content, :dossier_folder, :export_pdf, :pjs

  DOSSIER_STATE = Dossier.states.fetch(:en_construction)
  FORMAT_DATE = "%Y-%m-%d"

  def pj(stable_id)
    pjs.find { _1['stable_id'] == stable_id.to_s }
  end

  def set_default_values
    self.dossier_folder = { "template" => path_with_dossier_id_suffix("dossier"), "enabled" => true }
    self.export_pdf = { "template" => path_with_dossier_id_suffix("export"), "enabled" => true }

    self.pjs = procedure.exportables_pieces_jointes.map do |pj|
      nice_libelle = transliterate(pj.libelle).downcase
        .gsub(/[^0-9a-z\-\_]/, ' ').gsub(/[[:space:]]+/, ' ').strip
        .then { truncate(_1, omission: '', separator: ' ') }.parameterize

      {
        "stable_id" => pj.stable_id.to_s,
        "template" => path_with_dossier_id_suffix(nice_libelle),
        "enabled" => false
      }
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
    render_attributes_for(dossier_folder['template'], dossier)
  end

  def export_pdf_path(dossier)
    "#{render_attributes_for(export_pdf['template'], dossier)}.pdf"
  end

  def pj_path(dossier, pj_stable_id, attachment = nil)
    render_attributes_for(pj(pj_stable_id)['template'], dossier, attachment)
  end

  def attachment_path(dossier, attachment, index: 0, row_index: nil, champ: nil)
    return File.join(folder_path(dossier), export_pdf_path(dossier)) if attachment.name == 'pdf_export_for_instructeur'

    dir_path = case attachment.record_type
    when 'Champ'
      [pj_path(dossier, champ.stable_id, attachment) + suffix(attachment, index, row_index)] if pj(champ.stable_id)
    else
      nil
    end

    File.join(folder_path(dossier), File.join(dir_path)) if dir_path.present?
  end

  private

  def path_with_dossier_id_suffix(prefix)
    {
      "type" => "doc",
      "content" => [
        { "type" => "paragraph", "content" => [{ "text" => "#{prefix}-", "type" => "text" }, { "type" => "mention", "attrs" => DOSSIER_ID_TAG.slice(:id, :label).stringify_keys }] }
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
