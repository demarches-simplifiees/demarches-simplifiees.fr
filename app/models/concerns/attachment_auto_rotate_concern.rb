module AttachmentAutoRotateConcern
  extend ActiveSupport::Concern

  included do
    after_create_commit :auto_rotate
  end

  private

  def auto_rotate
    return if blob.nil?
    return if ["image/jpeg", "image/jpg"].exclude?(blob.content_type)

    blob.open do |file|
      Tempfile.create(["rotated", File.extname(file)]) do |output|
        processed = AutoRotateService.new.process(file, output)
        blob.upload(processed) # also update checksum & byte_size accordingly
        blob.save!
      end
    end
  end
end
