class Dsfr::DownloadComponent < ApplicationComponent
  renders_one :right

  attr_reader :attachment
  attr_reader :html_class
  attr_reader :name
  attr_reader :new_tab

  def initialize(attachment:, name: nil, url: nil, new_tab: false)
    @attachment = attachment
    @name = name || attachment.filename.to_s
    @url = url
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
