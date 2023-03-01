module Redcarpet
  class BareRenderer < Redcarpet::Render::HTML
    include ActionView::Helpers::TagHelper

    # won't use rubocop tag method because it is missing output buffer
    # rubocop:disable Rails/ContentTag
    def list(content, list_type)
      tag = list_type == :ordered ? :ol : :ul
      content_tag(tag, content, { class: @options[:class_names_map].fetch(:list) {} }, false)
    end

    def list_item(content, list_type)
      content_tag(:li, content.strip.gsub(/<\/?p>/, ''), {}, false)
    end

    def paragraph(text)
      content_tag(:p, text, { class: @options[:class_names_map].fetch(:paragraph) {} }, false)
    end
    # rubocop:enable Rails/ContentTag
  end
end
