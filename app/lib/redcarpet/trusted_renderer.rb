module Redcarpet
  class TrustedRenderer < Redcarpet::Render::HTML
    include ActionView::Helpers::TagHelper
    include Sprockets::Rails::Helper
    include ApplicationHelper

    attr_reader :view_context

    def initialize(view_context, extensions = {})
      @view_context = view_context

      super extensions
    end

    def link(href, title, content)
      html_options = {
        href: href
      }

      unless href.starts_with?('/')
        html_options.merge!(title: new_tab_suffix(title), **external_link_attributes)
      end

      content_tag(:a, content, html_options, false)
    end

    def autolink(link, link_type)
      case link_type
      when :url
        link(link, nil, link)
      when :email
        # NOTE: As of Redcarpet 3.6.0, autolinking email containing underscore is broken https://github.com/vmg/redcarpet/issues/402
        content_tag(:a, link, { href: "mailto:#{link}" })
      end
    end

    def image(link, title, alt)
      view_context.image_tag(link, title:, alt:, loading: :lazy)
    end
  end
end
