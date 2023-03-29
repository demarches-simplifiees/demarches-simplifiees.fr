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

  def initialize(text, allow_a: true, class_names_map: {})
    @text = (text || "").gsub(/\R/, "\n\n") # force double \n otherwise a single one won't split paragraph
      .split("\n\n")  #
      .map(&:lstrip)  # this block prevent redcarpet to consider "   text" as block code by lstriping
      .join("\n\n")   #
    @allow_a = allow_a
    @renderer = Redcarpet::Markdown.new(
      Redcarpet::BareRenderer.new(link_attributes: external_link_attributes, class_names_map: class_names_map),
      REDCARPET_EXTENSIONS.merge(autolink: @allow_a)
    )
  end

  def external_link_attributes
    { target: '_blank', rel: 'noopener noreferrer' }
  end

  def tags
    if @allow_a
      Rails.configuration.action_view.sanitized_allowed_tags + ['a']
    else
      Rails.configuration.action_view.sanitized_allowed_tags
    end
  end

  def attributes
    ['target', 'rel', 'href', 'class']
  end
end
