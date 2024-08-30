# frozen_string_literal: true

class ChampPresentations::MultipleDropDownListPresentation < ChampPresentations::BasePresentation
  attr_reader :selected_options

  def initialize(selected_options)
    @selected_options = selected_options
  end

  def to_s
    selected_options.join(', ')
  end

  def to_tiptap_node
    {
      type: 'bulletList',
      content: selected_options.map do |text|
        {
          type: 'listItem',
          content: [
            {
              type: 'paragraph',
              content: [
                {
                  type: 'text',
                  text: text
                }
              ]
            }
          ]
        }
      end
    }
  end
end
