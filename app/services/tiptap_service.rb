class TiptapService
  def to_html(node, substitutions = {})
    return '' if node.nil?

    children(node[:content], substitutions, 0)
  end

  def to_path(node, substitutions = {})
    return '' if node.nil?

    children_path(node[:content], substitutions)
  end

  # NOTE: node must be deep symbolized keys
  def used_tags_and_libelle_for(node, tags = Set.new)
    case node
    in type: 'mention', attrs: { id:, label: }, **rest
      tags << [id, label]
    in { content:, **rest } if content.is_a?(Array)
      content.each { used_tags_and_libelle_for(_1, tags) }
    in type:, **rest
      # noop
    end

    tags
  end

  private

  def initialize
    @body_started = false
  end

  def children_path(content, substitutions)
    content.map { node_to_path(_1, substitutions) }.join
  end

  def node_to_path(node, substitutions)
    case node
    in type: 'paragraph', content:
      children_path(content, substitutions)
    in type: 'text', text:, **rest
      text.strip
    in type: 'mention', attrs: { id: }, **rest
      text = substitutions.fetch(id) { "--#{id}--" }
    end
  end

  def children(content, substitutions, level)
    content.map { node_to_html(_1, substitutions, level) }.join
  end

  def node_to_html(node, substitutions, level)
    if level == 0 && !@body_started && node[:type].in?(['paragraph', 'heading']) && node.key?(:content)
      @body_started = true
      body_start_mark = " class=\"body-start\""
    end

    case node
    in type: 'header', content:
      "<header>#{children(content, substitutions, level + 1)}</header>"
    in type: 'footer', content:, **rest
      "<footer#{text_align(rest[:attrs])}>#{children(content, substitutions, level + 1)}</footer>"
    in type: 'headerColumn', content:, **rest
      "<div#{text_align(rest[:attrs])}>#{children(content, substitutions, level + 1)}</div>"
    in type: 'paragraph', content:, **rest
      "<p#{body_start_mark}#{text_align(rest[:attrs])}>#{children(content, substitutions, level + 1)}</p>"
    in type: 'title', content:, **rest
      "<h1#{text_align(rest[:attrs])}>#{children(content, substitutions, level + 1)}</h1>"
    in type: 'heading', attrs: { level: hlevel, **attrs }, content:
      "<h#{hlevel}#{body_start_mark}#{text_align(attrs)}>#{children(content, substitutions, level + 1)}</h#{hlevel}>"
    in type: 'bulletList', content:
      "<ul>#{children(content, substitutions, level + 1)}</ul>"
    in type: 'orderedList', content:
      "<ol>#{children(content, substitutions, level + 1)}</ol>"
    in type: 'listItem', content:
      "<li>#{children(content, substitutions, level + 1)}</li>"
    in type: 'text', text:, **rest
      if rest[:marks].present?
        apply_marks(text, rest[:marks])
      else
        text
      end
    in type: 'mention', attrs: { id: }, **rest
      text = substitutions.fetch(id) { "--#{id}--" }

      if rest[:marks].present?
        apply_marks(text, rest[:marks])
      else
        text
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
