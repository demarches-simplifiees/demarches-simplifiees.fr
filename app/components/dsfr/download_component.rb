# frozen_string_literal: true

class Dsfr::DownloadComponent < ApplicationComponent
  attr_reader :attachment
  attr_reader :html_class
  attr_reader :name
  attr_reader :ephemeral_link
  attr_reader :virus_not_analyzed
  attr_reader :new_tab
  attr_reader :truncate
  attr_reader :has_name

  def initialize(attachment:, name: nil, url: nil, ephemeral_link: false, virus_not_analyzed: false, new_tab: false, truncate: false, has_name: false)
    @attachment = attachment
    @name = name || attachment.filename.to_s
    @url = url
    @ephemeral_link = ephemeral_link
    @virus_not_analyzed = virus_not_analyzed
    @new_tab = new_tab
    @truncate = truncate
    @has_name = has_name
  end

  def url
    return @url if @url.present?

    Rails.application.routes.url_helpers.rails_blob_url(@attachment.blob, disposition: 'attachment')
  end
end
