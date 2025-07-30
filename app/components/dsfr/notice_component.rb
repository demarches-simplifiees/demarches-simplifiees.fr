# frozen_string_literal: true

# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/bandeau-d-information-importante/
class Dsfr::NoticeComponent < ApplicationComponent
  renders_one :title
  renders_one :desc
  renders_one :link

  attr_reader :data_attributes

  def initialize(closable: false, state: 'info', data_attributes: {})
    @closable = closable
    @data_attributes = data_attributes
    @state = state
  end

  def options
    data_attributes.merge(class: "fr-notice fr-notice--#{@state}").merge(notice_data_attributes)
  end

  def closable?
    !!@closable
  end

  def notice_data_attributes
    { "data-controller": 'dsfr-notice', "data-dsfr-notice-target": "notice" }.merge(data_attributes)
  end
end
