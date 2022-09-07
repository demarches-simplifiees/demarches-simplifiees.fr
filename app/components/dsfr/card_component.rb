class Dsfr::CardComponent < ApplicationComponent
  renders_many :footer_buttons

  private

  def initialize(title: nil, desc: nil)
    @title = title
    @desc = desc
  end

  attr_reader :title, :desc
end
