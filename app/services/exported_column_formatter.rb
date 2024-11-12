# frozen_string_literal: true

class ExportedColumnFormatter
  def self.format(column:, champ_or_dossier:, format:)
    return if champ_or_dossier.nil?

    raw_value = column.value(champ_or_dossier)

    case column.type
    when :boolean
      format_boolean(column:, raw_value:, format:)
    when :attachements
      format_attachments(column:, raw_value:)
    when :enum
      format_enum(column:, raw_value:)
    when :enums
      format_enums(column:, raw_values: raw_value)
    else
      raw_value
    end
  end

  private

  def self.format_boolean(column:, raw_value:, format:)
    if format == :ods
      raw_value ? 1 : 0
    else
      raw_value
    end
  end

  def self.format_attachments(column:, raw_value:)
    case column.tdc_type
    when TypeDeChamp.type_champs[:titre_identite]
      raw_value.present? ? 'présent' : 'absent'
    when TypeDeChamp.type_champs[:piece_justificative]
      raw_value.map { _1.blob.filename }.join(", ")
    end
  end

  def self.format_enums(column:, raw_values:)
    raw_values.map { format_enum(column:, raw_value: _1) }.join(', ')
  end

  def self.format_enum(column:, raw_value:)
    # options for select store ["trad", :enum_value]
    selected_option = column.options_for_select.find { _1[1].to_s == raw_value }

    selected_option ? selected_option.first : raw_value
  end
end
