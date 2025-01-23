module LexpolFieldsService
  def self.object_field_values(source, field, log_empty: true)
    return [] if source.blank? || field.blank?

    objects = [source]
    field.split('.').each do |segment|
      objects = objects.flat_map do |object|
        results = []
        results += dossier_linked_champs(object)             if object.respond_to?(:dossier)
        results += select_champ(object.champs, segment)      if object.respond_to?(:champs)
        results += select_champ(object.annotations, segment) if object.respond_to?(:annotations)
        results += select_champ(object.rows, segment)        if object.respond_to?(:rows)
        results += attributes(object, segment)               if object.respond_to?(segment)
        results
      end

      if log_empty && objects.blank?
        Rails.logger.warn("Dans LexpolFieldsService, le champ '#{field}' est vide après '#{segment}'.")
      end
    end

    objects = objects.uniq
  end

  def self.select_champ(object, name)
    return [] if object.blank?

    if object.respond_to?(:to_a)
      object.to_a.flat_map { |item| select_champ(item, name) }
    else
      object.type_de_champ&.libelle == name ? [object] : []
    end
  end

  def self.attributes(object, name)
    value = object.send(name)

    if value.is_a?(Date)
      return [format_date(value)]
    elsif value.is_a?(Time) || value.is_a?(DateTime)
      return [format_datetime(value)]
    end

    value.is_a?(Array) ? value : [value].compact
  end

  def self.dossier_linked_champs(object)
    Rails.logger.debug { "Navigating to linked dossier for #{object.inspect}" }
    dossier_linked = Dossier.find_by(id: object.value)
    object.dossier
    dossier_linked ? dossier_linked.champs : []
  end

  def self.format_lexpol_value(champ)
    case champ
    when Champs::DatetimeChamp
      format_datetime(champ.value)
    when Champs::DateChamp
      format_date(champ.value)
    when Champs::RepetitionChamp
      format_repetition_champ(champ)
    when Champs::TextareaChamp
      format_markdown(champ.value)
    else
      champ.respond_to?(:value) ? champ.value.to_s : champ.to_s
    end
  end

  def self.format_date(date)
    return '' if date.blank?
    begin
      parsed = date.is_a?(String) ? Date.parse(date) : date
      parsed.strftime('%d/%m/%Y')
    rescue
      date.to_s
    end
  end

  def self.format_datetime(date)
    return '' if date.blank?
    begin
      parsed = date.is_a?(String) ? DateTime.parse(date) : date
      parsed.strftime('%d/%m/%Y à %H:%M')
    rescue
      date.to_s
    end
  end

  def self.format_repetition_champ(repeat_champ)
    rows = repeat_champ.rows
    return '' if rows.blank?

    filtered_rows = rows.map do |row|
      row.reject { |champ| ignore_champ?(champ) }
    end

    return '' if filtered_rows.all?(&:empty?)

    <<~HTML
      <table style="margin: 0 auto; border-collapse: collapse;" border="1">
        #{table_header_row(filtered_rows.first)}
        <tbody>
          #{filtered_rows.each_with_index.map { |row, i| table_body_row(row, i) }.join}
        </tbody>
      </table>
    HTML
  end

  def self.table_header_row(row)
    return '' unless row.is_a?(Array)

    "<thead><tr>" +
      row.map { |c| "<th>#{c.type_de_champ.libelle}</th>" }.join +
    "</tr></thead>"
  end

  def self.table_body_row(row, index)
    return '' if row.blank?

    background = (index.even? ? "#F0F0F0" : "#FFFFFF")

    "<tr style='background-color: #{background};'>" +
      row.map do |champ|
        # format
        value = format_lexpol_value(champ)
        "<td style='vertical-align: middle; text-align: left;'>#{value}</td>"
      end.join +
    "</tr>"
  end

  def self.format_markdown(markdown_str)
    return '' if markdown_str.blank?

    renderer = Redcarpet::Render::HTML.new(filter_html: false, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)

    markdown.render(markdown_str)
  end

  def self.render_lexpol_values(final_values)
    return '' if final_values.blank?
    final_values.size == 1 ? final_values.first : final_values.join('<br>')
  end

  def self.ignore_champ?(champ)
    champ.is_a?(Champs::HeaderSectionChamp) || champ.is_a?(Champs::ExplicationChamp)
  end
end
