class ExportTemplate::ChampsComponent < ApplicationComponent
  attr_reader :sections, :export_template, :title

  def initialize(title, export_template, types_de_champ)
    @title = title
    @export_template = export_template
    @types_de_champ = types_de_champ
    @sections ||= to_sections
  end

  def pretty_libelle(column)
    prefix = ''
    if column[:repetition_champ_stable_id]
      prefix = "(Bloc répétable #{column[:repetition_libelle]}) "
    end

    [prefix, column[:libelle]].join
  end

  private

  def to_sections
    sections = []
    current_section = { columns: [] }
    @types_de_champ.each do |current_tdc|
      if current_tdc.header_section?
        sections.push(current_section) if current_section[:columns].any?
        current_section = { libelle: current_tdc.libelle, columns: [] }
      else
        current_section[:columns].push(tdc_to_columns(current_tdc))
      end
    end
    sections.push(current_section) if current_section[:columns].any?
    sections
  end

  def tdc_to_columns(type_de_champ)
    if type_de_champ.repetition?
      types_de_champ = export_template.procedure.types_de_champ_for_procedure_presentation(type_de_champ)

      if types_de_champ.present?
        types_de_champ.flat_map do |tdc|
          tdc.columns_for_export(repetition_champ_stable_id: type_de_champ.stable_id).map do
            _1.merge({ repetition_libelle: type_de_champ.libelle, libelle: export_template.saved_libelle(_1) || _1[:libelle] })
          end
        end
      end
    else
      type_de_champ.columns_for_export.map do
        _1.merge({ libelle: export_template.saved_libelle(_1) || _1[:libelle] })
      end
    end
  end
end
