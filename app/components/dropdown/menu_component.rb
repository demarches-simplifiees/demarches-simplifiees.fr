class Dropdown::MenuComponent < ApplicationComponent
  renders_one :button_inner_html
  # beware, items elements like button_to/link_to must include role: 'menuitem' for aria reason
  renders_many :items, -> (options = {}, &block) do
    tag.li({ role: 'none' }.merge(options), &block)
  end
  renders_many :forms

  def initialize(wrapper:,
    wrapper_options: {},
    button_options: {},
    menu_options: {})
    @wrapper = wrapper
    @wrapper_options = wrapper_options
    @button_options = button_options
    @menu_options = menu_options
  end

  def wrapper_options
    @wrapper_options.deep_merge({
      class: wrapper_class_names,
      data: { controller: 'menu-button' }
    })
  end

  def wrapper_class_names
    ['dropdown'] + Array(@wrapper_options[:class])
  end

  def button_id
    "#{menu_id}_button"
  end

  def menu_id
    @menu_options[:id] ||= SecureRandom.uuid
    @menu_options[:id]
  end

  def menu_role
    forms? ? :region : :menu
  end

  def menu_class_names
    ['dropdown-content'] + Array(@menu_options[:class])
  end

  def button_class_names
    ['fr-btn', 'dropdown-button'] + Array(@button_options[:class])
  end
end
