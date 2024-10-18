# frozen_string_literal: true

class ExportTemplateValidator < ActiveModel::Validator
  def validate(export_template)
    return if !export_template.template_zip?

    validate_all_templates(export_template)

    return if export_template.errors.any? # no need to continue if the templates are invalid

    validate_dossier_folder(export_template)
    validate_export_pdf(export_template)
    validate_pjs(export_template)

    validate_different_templates(export_template)
  end

  private

  def validate_all_templates(export_template)
    [export_template.dossier_folder, export_template.export_pdf, *export_template.pjs].each(&:template_string)

  rescue StandardError
    export_template.errors.add(:base, :invalid_template)
  end

  def validate_dossier_folder(export_template)
    if !mentions(export_template.dossier_folder.template).include?('dossier_number')
      export_template.errors.add(:dossier_folder, :dossier_number_required)
    end
  end

  def mentions(template)
    TiptapService.used_tags_and_libelle_for(template).map(&:first)
  end

  def validate_export_pdf(export_template)
    return if !export_template.export_pdf.enabled?

    if export_template.export_pdf.template_string.empty?
      export_template.errors.add(:export_pdf, :blank)
    end
  end

  def validate_pjs(export_template)
    libelle_by_stable_ids = pj_libelle_by_stable_id(export_template)

    export_template.pjs.filter(&:enabled?).each do |pj|
      if pj.template_string.empty?
        libelle = libelle_by_stable_ids[pj.stable_id]
        export_template.errors.add(libelle, I18n.t(:blank, scope: 'errors.messages'))
      end
    end
  end

  def validate_different_templates(export_template)
    templates = [export_template.export_pdf, *export_template.pjs]
      .filter(&:enabled?)
      .map(&:template_string)

    return if templates.uniq.size == templates.size

    export_template.errors.add(:base, :different_templates)
  end

  def pj_libelle_by_stable_id(export_template)
    export_template.procedure.exportables_pieces_jointes
      .pluck(:stable_id, :libelle).to_h
  end
end
