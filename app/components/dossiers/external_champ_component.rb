# frozen_string_literal: true

class Dossiers::ExternalChampComponent < ApplicationComponent
  renders_one :header

  attr_reader :data, :details, :source, :details_footer

  def initialize(data: [], details: [], source: nil, details_footer: nil)
    # rubocop:disable Rails/CompactBlank
    @data = data.filter { |_, value| value.present? }
    @details = details.filter { |_, value| value.present? }
    # rubocop:enable Rails/CompactBlank
    @source = source
    @details_footer = details_footer
  end
end
