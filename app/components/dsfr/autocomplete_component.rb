class Dsfr::AutocompleteComponent < ApplicationComponent
  renders_many :options

  def initialize(id:)
    @id = id
  end

  private

  def listbox_id
    "#{@id}-listbox"
  end

  def input_id
    @id
  end

  def option_id(index)
    "#{@id}-option-#{index}"
  end

  def input_wrapper_html_options
    {
      role: "combobox",
      'aria-haspopup': "listbox",
      'aria-expanded': "false",
      'aria-owns': list_id,
      'data-autocomplete-target': "combobox"
    }
  end

  def input_html_options
    {
      type: "text",
      id: input_id,
      'data-action': "input->autocomplete#onInput blur->autocomplete#onInputBlur click->autocomplete#onInputClick keydown->autocomplete#onInputKeyDown",
      'data-autocomplete-target': "input",
      'aria-activedescendant': "",
      'aria-autocomplete': "list"
    }
  end

  def listbox_html_options
    {
      role: "listbox",
      id: listbox_id,
      'data-autocomplete-target': "listbox"
    }
  end

  def option_html_options(index)
    {
      role: 'option',
      id: option_id(index),
      'data-autocomplete-target': 'option',
      'data-action': "click->autocomplete#onOptionClick mousedown->autocomplete#onOptionMouseDown",
      'data-autocomplete-index-param': index
    }
  end
end
