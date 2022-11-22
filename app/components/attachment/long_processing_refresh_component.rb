class Attachment::LongProcessingRefreshComponent < ApplicationComponent
  def initialize(attachment: nil)
    @attachment = attachment
  end
end
