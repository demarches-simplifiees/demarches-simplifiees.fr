class TiptapService
  def to_html(node, tags)
    return '' if node.nil?

    children(node[:content], tags, 0)
  end

  private

  def initialize
    @body_started = false
  end

  def children(content, tags, level)
    content.map { node_to_html(_1, tags, level) }.join
  end

  def node_to_html(node, tags, level)
    if level == 0 && !@body_started && node[:type] == 'paragraph' && node.key?(:content)
      @body_started = true
      body_start_mark = " class=\"body-start\""
    end

    case node
    in type: 'header', content:
      "<header>#{children(content, tags, level + 1)}</header>"
    in type: 'footer', content:, **rest
      "<footer#{text_align(rest[:attrs])}>#{children(content, tags, level + 1)}</footer>"
    in type: 'headerColumn', content:, **rest
      "<div#{text_align(rest[:attrs])}>#{children(content, tags, level + 1)}</div>"
    in type: 'paragraph', content:, **rest
      "<p#{body_start_mark}#{text_align(rest[:attrs])}>#{children(content, tags, level + 1)}</p>"
    in type: 'title', content:, **rest
      "<h1#{text_align(rest[:attrs])}>#{children(content, tags, level + 1)}</h1>"
    in type: 'heading', attrs: { level: hlevel, **attrs }, content:
      "<h#{hlevel}#{text_align(attrs)}>#{children(content, tags, level + 1)}</h#{hlevel}>"
    in type: 'bulletList', content:
      "<ul>#{children(content, tags, level + 1)}</ul>"
    in type: 'orderedList', content:
      "<ol>#{children(content, tags, level + 1)}</ol>"
    in type: 'listItem', content:
      "<li>#{children(content, tags, level + 1)}</li>"
    in type: 'text', text:, **rest
      if rest[:marks].present?
        apply_marks(text, rest[:marks])
      else
        text
      end
    in type: 'mention', attrs: { id: }, **rest
      if rest[:marks].present?
        apply_marks("--#{id}--", rest[:marks])
      else
        "--#{id}--"
      end
    in { type: type } if ["paragraph", "title", "heading"].include?(type) && !node.key?(:content)
      # noop
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
