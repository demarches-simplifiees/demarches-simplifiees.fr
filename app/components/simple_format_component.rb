class SimpleFormatComponent < ApplicationComponent
  # see: https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
  REDCARPET_EXTENSIONS = {
    no_intra_emphasis: true,
    disable_indented_code_blocks: true,
    space_after_headers: true,
    tables: false,
    fenced_code_blocks: false,
    autolink: false,
    strikethrough: false,
    lax_spacing: false,
    superscript: false,
    underline: false,
    highlight: false,
    quote: false,
    footnotes: false
  }

  # see: https://github.com/vmg/redcarpet#darling-i-packed-you-a-couple-renderers-for-lunch
  REDCARPET_RENDERER_OPTS = {
    no_images: true
  }

  SIMPLE_URL_REGEX = %r{https?://\S+}
  EMAIL_IN_TEXT_REGEX = Regexp.new(Devise.email_regexp.source.gsub(/\\A|\\z/, '\b'))

  def initialize(text, allow_a: true, class_names_map: {})
    @allow_a = allow_a

    list_item = false
    lines = (text || "")
      .lines
      .map(&:lstrip) # this block prevent redcarpet to consider "   text" as block code by lstriping

    @text = lines.map do |line|
      item_number = line.match(/\A(\d+)\./)
      if item_number.present?
        list_item = true
        "\n" + line + "[value:#{item_number[1]}]"
      elsif line.match?(/\A[-*+]\s/)
        list_item = true
        "\n" + line
      elsif line == ''
        list_item = false
        "\n" + line
      elsif list_item
        line
      else
        "\n" + line
      end
    end.join.lstrip

    @renderer = Redcarpet::Markdown.new(
      Redcarpet::BareRenderer.new(class_names_map:),
      REDCARPET_EXTENSIONS.merge(autolink: @allow_a)
    )
  end

  def tags
    if @allow_a
      Rails.configuration.action_view.sanitized_allowed_tags + ['a']
    else
      Rails.configuration.action_view.sanitized_allowed_tags
    end
  end

  def attributes
    ['target', 'rel', 'href', 'class', 'title', 'value']
  end
end
