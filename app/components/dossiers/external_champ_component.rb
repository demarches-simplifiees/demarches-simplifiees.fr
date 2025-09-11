# frozen_string_literal: true

class Dossiers::ExternalChampComponent < ApplicationComponent
  renders_one :header

  attr_reader :title, :data, :details, :source, :details_footer

  def initialize(title:, data: [], details: [], source: nil, details_footer: nil)
    @title = title
    @data = data.filter { |_, value| value.present? }
    @details = details.filter { |_, value| value.present? }
    @source = source
    @details_footer = details_footer
  end
end
