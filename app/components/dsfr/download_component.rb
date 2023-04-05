class Dsfr::DownloadComponent < ApplicationComponent
  renders_one :right

  attr_reader :attachment
  attr_reader :html_class
  attr_reader :name

  def initialize(attachment:, name: nil, url: nil)
    @attachment = attachment
    @name = name || attachment.filename.to_s
    @url = url
  end

  def title
    t(".title", filename: attachment.filename.to_s)
  end

  def url
    return @url if @url.present?

    helpers.url_for(@attachment.blob)
  end
end
