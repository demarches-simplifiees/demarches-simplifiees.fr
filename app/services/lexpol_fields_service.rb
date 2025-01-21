module LexpolFieldsService
  def self.object_field_values(source, field, log_empty: true)
    return [] if source.blank? || field.blank?

    objects = [source]
    field.split('.').each do |segment|
      objects = objects.flat_map do |object|
        if object.is_a?(Champs::RepetitionChamp)
          select_champ(object.rows, segment)
        else
          results = []
          results += dossier_linked_champs(object)             if object.is_a?(Champs::DossierLinkChamp) && object.respond_to?(:dossier)
          results += select_champ(object.champs, segment)      if object.respond_to?(:champs)
          results += select_champ(object.annotations, segment) if object.respond_to?(:annotations)
          results += attributes(object, segment)               if object.respond_to?(segment)
          results
        end
      end

      if log_empty && objects.blank?
        Rails.logger.warn("Dans LexpolFieldsService, le champ '#{field}' est vide après '#{segment}'.")
      end
    end

    objects
  end

  def self.select_champ(collection, name)
    return [] if collection.blank?

    collection.flat_map do |item|
      if item.is_a?(Array)
        item.filter { |champ| champ.type_de_champ&.libelle == name }
      else
        item.type_de_champ&.libelle == name ? item : nil
      end
    end.compact
  end

  def self.attributes(object, name)
    value = object.send(name)

    if value.is_a?(Date) || value.is_a?(Time) || value.is_a?(DateTime)
      return [format_date(value)]
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
      parsed.strftime('%d/%m/%Y %H:%M')
    rescue
      date.to_s
    end
  end

  def self.format_repetition_champ(repeat_champ)
    return '' if repeat_champ.rows.blank?

    <<~HTML
      <table border="1" style="border-collapse:collapse;">
        #{table_header_row(repeat_champ.rows.first)}
        <tbody>
          #{repeat_champ.rows.map { |row| table_body_row(row) }.join}
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

  def self.table_body_row(row)
    return '' unless row.is_a?(Array)

    "<tr>" +
      row.map { |c| "<td>#{(c.value || '')}</td>" }.join +
    "</tr>"
  end

  def self.format_markdown(markdown_str)
    return '' if markdown_str.blank?

    renderer = Redcarpet::Render::HTML.new(filter_html: false, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)

    markdown.render(markdown_str)
  end
end
