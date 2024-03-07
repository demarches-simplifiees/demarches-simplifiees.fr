class TiptapService
  class << self
    def to_html(node, tags)
      return '' if node.nil?

      children(node[:content], tags)
    end

    private

    def children(content, tags)
      content.map { node_to_html(_1, tags) }.join
    end

    def node_to_html(node, tags)
      case node
      in type: 'paragraph', content:, **rest
        "<p#{text_align(rest[:attrs])}>#{children(content, tags)}</p>"
      in type: 'heading', attrs: { level:, **attrs }, content:
        "<h#{level}#{text_align(attrs)}>#{children(content, tags)}</h#{level}>"
      in type: 'bulletList', content:
        "<ul>#{children(content, tags)}</ul>"
      in type: 'orderedList', content:
        "<ol>#{children(content, tags)}</ol>"
      in type: 'listItem', content:
        "<li>#{children(content, tags)}</li>"
      in type: 'text', text:, **rest
        if rest[:marks].present?
          apply_marks(text, rest[:marks])
        else
          text
        end
      in type: 'mention', attrs: { id: }, **rest
        if rest[:marks].present?
          apply_marks(tags[id], rest[:marks])
        else
          tags[id]
        end
      end
    end

    def text_align(attrs)
      if attrs.present? && attrs[:textAlign].present?
        " style=\"text-align: #{attrs[:textAlign]}\""
      else
        ""
      end
    end

    def apply_marks(text, marks)
      marks.reduce(text) do |text, mark|
        case mark
        in type: 'bold'
          "<strong>#{text}</strong>"
        in type: 'italic'
          "<em>#{text}</em>"
        in type: 'underline'
          "<u>#{text}</u>"
        in type: 'strike'
          "<s>#{text}</s>"
        in type: 'highlight'
          "<mark>#{text}</mark>"
        end
      end
    end
  end
end
