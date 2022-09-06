class Dsfr::CardComponent < ApplicationComponent
  def footer_button(*args)
    @footer_buttons.push args
  end

  private

  def initialize(title: nil, desc: nil, footer_buttons: [])
    @title = title
    @desc = desc
    @footer_buttons = footer_buttons
  end

  attr_reader :title, :desc, :footer_buttons
end
