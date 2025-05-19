# frozen_string_literal: true

# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/bandeau-d-information-importante/
class Dsfr::NoticeComponent < ApplicationComponent
  renders_one :title
  renders_one :desc
  renders_one :link

  attr_reader :data_attributes

  def initialize(closable: false, data_attributes: {})
    @closable = closable
    @data_attributes = data_attributes
  end

  def closable?
    !!@closable
  end

  def notice_data_attributes
    { "data-dsfr-header-target": "notice" }.merge(data_attributes)
  end
end
