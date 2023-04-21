class SimpleFormatComponent < ApplicationComponent
  # see: https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
  REDCARPET_EXTENSIONS = {
    no_intra_emphasis: false,
    tables: false,
    fenced_code_blocks: false,
    autolink: false,
    disable_indented_code_blocks: false,
    strikethrough: false,
    lax_spacing: false,
    space_after_headers: false,
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

    @text = (text || "").gsub(/\R/, "\n\n") # force double \n otherwise a single one won't split paragraph
      .split("\n\n")  #
      .map(&:lstrip)  # this block prevent redcarpet to consider "   text" as block code by lstriping
      .join("\n\n")
      .gsub(EMAIL_IN_TEXT_REGEX) { _1.gsub('_', '\\_') } # Workaround for redcarpet bug on autolink email having _. Cf tests

    if !@allow_a
      @text = @text.gsub(SIMPLE_URL_REGEX) { _1.gsub('_', '\\_') } # Escape underscores in URLs
    end

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
    ['target', 'rel', 'href', 'class', 'title']
  end
end
