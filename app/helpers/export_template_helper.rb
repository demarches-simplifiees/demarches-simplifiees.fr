# frozen_string_literal: true

module ExportTemplateHelper
  def pretty_kind(kind)
    icon = kind == 'zip' ? 'archive' : 'table'
    pretty = tag.span nil, class: "fr-icon-#{icon}-line fr-mr-1v"
    pretty += kind.upcase
  end
end
