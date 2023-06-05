class Dsfr::DownloadComponent < ApplicationComponent
  attr_reader :attachment
  attr_reader :html_class
  attr_reader :name
  attr_reader :ephemeral_link
  attr_reader :virus_not_analized
  attr_reader :new_tab

  def initialize(attachment:, name: nil, url: nil, ephemeral_link: false, virus_not_analized: false, new_tab: false)
    @attachment = attachment
    @name = name || attachment.filename.to_s
    @url = url
    @ephemeral_link = ephemeral_link
    @virus_not_analized = virus_not_analized
    @new_tab = new_tab
  end

  def title
    t(".title", filename: attachment.filename.to_s)
  end

  def url
    return @url if @url.present?

    helpers.url_for(@attachment.blob)
  end
end
