module LexpolFieldsService
  def self.object_field_values(source, field)
    return [] if source.blank? || field.blank?

    field.split('.').reduce([source]) do |objects, segment|
      objects.flat_map do |object|
        if object.respond_to?(segment)
          attributes(object, segment)
        elsif object.respond_to?(:rows)
          object.rows.flat_map { |row| select_champ(row, segment) }
        else
          object = dereference(object)
          results = []
          results += select_champ(object.champs, segment) if object.respond_to?(:champs)
          results += select_champ(object.annotations, segment) if object.respond_to?(:annotations)
          results += attributes(object, segment) if object.respond_to?(:segment)
          results
        end
      end
    end
  end

  def self.select_champ(champs, name)
    champs.filter { |champ| champ.libelle == name }
  end

  def self.attributes(object, name)
    r = object.send(name)
    r.is_a?(Array) ? r : [r]
  end

  def self.format_lexpol_value(object)
    case object
    when Champs::DatetimeChamp
      format_datetime(object.value)
    when Champs::DateChamp
      format_date(object.value)
    when Champs::RepetitionChamp
      format_repetition_champ(object)
    when Champs::TextareaChamp
      format_markdown(object.value)
    when Date
      format_date(object)
    when DateTime, Time
      format_datetime(object)
    else
      object.respond_to?(:value) ? object.value.to_s : object.to_s
    end
  end

  def self.format_date(date)
    return '' if date.blank?
    begin
      parsed = date.is_a?(String) ? Date.parse(date) : date
      I18n.l(parsed, format: '%-d %B %Y')
    rescue
      date.to_s
    end
  end

  def self.format_datetime(date)
    return '' if date.blank?
    begin
      parsed = date.is_a?(String) ? DateTime.parse(date) : date
      I18n.l(parsed, format: '%-d %B %Y à %H:%M')
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

    <<~HTML.delete("\n")
      <table class="table table-bordered" style="margin: 0px auto !important;">
        <tbody>
          #{table_header_row(filtered_rows.first)}
          #{filtered_rows.each_with_index.map { |row, i| table_body_row(row, i) }.join}
        </tbody>
      </table>
    HTML
  end

  def self.table_header_row(row)
    return '' unless row.is_a?(Array)

    "<tr>" +
      row.map { |c| "<td style='background-color: #505050;color:#FFFFFF;padding:7px'>#{c.type_de_champ.libelle}</td>" }.join +
      "</tr></thead>"
  end

  def self.table_body_row(row, index)
    return '' if row.blank?

    background = (index.even? ? "#F0F0F0" : "#FFFFFF")

    "<tr style='background-color: #{background};'>" +
      row.map do |champ|
        # format
        value = format_lexpol_value(champ)
        "<td style='vertical-align: middle; text-align: left;padding: 5px'>#{value}</td>"
      end.join +
      "</tr>"
  end

  def self.format_markdown(markdown_str)
    return '' if markdown_str.blank?

    renderer = Redcarpet::Render::HTML.new(filter_html: false, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)

    markdown.render(markdown_str).delete("\n")
  end

  def self.ignore_champ?(champ)
    champ.is_a?(Champs::HeaderSectionChamp) || champ.is_a?(Champs::ExplicationChamp)
  end

  private

  def self.dereference(object)
    object.is_a?(Champs::DossierLinkChamp) ? object.dossier : object
  end
end
