class Dsfr::DownloadComponent < ApplicationComponent
  renders_one :right

  attr_reader :attachment
  attr_reader :html_class
  attr_reader :name

  def initialize(attachment:, name: nil)
    @attachment = attachment
    @name = name || attachment.filename.to_s
  end

  def title
    "Télécharger le fichier #{attachment.filename}"
  end
end
