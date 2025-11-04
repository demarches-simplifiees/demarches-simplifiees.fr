# frozen_string_literal: true

class Attachment::ThumbnailComponent < ApplicationComponent
  include GalleryHelper

  attr_reader :attachment, :small, :top_classes, :thumbnail_url
  delegate :blob, :record, to: :attachment

  def initialize(attachment:, small: false, top_classes: '')
    @attachment, @small, @top_classes = attachment, small, top_classes
    @thumbnail_url = representation_url_for(attachment)
  end

  def size_class = small ? 'thumbnail-100' : 'thumbnail-200'

  def galleryable? = displayable_image?(blob) || displayable_pdf?(blob)

  def gallery_link(&block)
    if displayable_image?(blob)
      link_to image_url(blob_url(attachment)), title:, data: { src: blob.url }, class: 'gallery-link' do
        yield
      end
    elsif displayable_pdf?(blob)
      link_to blob.url, id: blob.id, data: { iframe: true, src: blob.url }, class: 'gallery-link', type: blob.content_type, title: do
        yield
      end
    end
  end

  def btn_text = small ? '' : 'Visualiser'

  private

  def title = "#{record_libelle(record)} -- #{sanitize(blob.filename.to_s)}"
end
