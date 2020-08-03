module AttachmentUploadHelper
  def image_upload_and_render(form, file, direct_upload = nil)
    render 'shared/attachment/edit', {
      form: form,
      attached_file: file,
      accept: 'image/png, image/jpg, image/jpeg',
      user_can_destroy: true,
      direct_upload: direct_upload
    }
  end

  def text_upload_and_render(form, file)
    render 'shared/attachment/edit', {
      form: form,
      attached_file: file,
      user_can_destroy: true
    }
  end
end
