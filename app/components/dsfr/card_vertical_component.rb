class Dsfr::CardVerticalComponent < ApplicationComponent
  renders_many :footer_buttons

  attr_reader :title, :desc

  def initialize(title: nil, desc: nil)
    @title = title
    @desc = desc
  end
end
