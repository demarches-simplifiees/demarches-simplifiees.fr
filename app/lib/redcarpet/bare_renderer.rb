module Redcarpet
  class BareRenderer < Redcarpet::Render::HTML
    include ActionView::Helpers::TagHelper
    include ApplicationHelper

    # won't use rubocop tag method because it is missing output buffer
    def list(content, list_type)
      tag = list_type == :ordered ? :ol : :ul
      content_tag(tag, content, { class: @options[:class_names_map].fetch(:list) {} }, false)
    end

    def list_item(content, list_type)
      item_number = content.match(/\[value:(\d+)\]/)
      text = content.strip
        .gsub(/<\/?p>/, '')
        .gsub(/\[value:\d+\]/, '')
        .gsub(/\n/, '<br>')
      attributes = item_number.present? ? { value: item_number[1] } : {}

      content_tag(:li, text, attributes, false)
    end

    def paragraph(text)
      content_tag(:p, text, { class: @options[:class_names_map].fetch(:paragraph) {} }, false)
    end

    def link(href, title, content)
      content_tag(:a, content, { href:, title: new_tab_suffix(title), **external_link_attributes }, false)
    end

    def autolink(link, link_type)
      case link_type
      when :url
        link(link, nil, link)
      when :email
        # NOTE: As of Redcarpet 3.6.0, autolinking email containing underscore is broken https://github.com/vmg/redcarpet/issues/402
        content_tag(:a, link, { href: "mailto:#{link}" })
      else
        link
      end
    end
  end
end
