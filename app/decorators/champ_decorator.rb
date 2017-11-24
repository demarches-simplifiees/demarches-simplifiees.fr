class ChampDecorator < Draper::Decorator
  delegate_all

  def description_with_links
    description.gsub(URI.regexp, '<a target="_blank" href="\0">\0</a>') if description
  end
end
