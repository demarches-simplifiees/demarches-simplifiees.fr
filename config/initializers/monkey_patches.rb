ActiveStorage::Identification.class_eval do
  def apply
    # Monkey patch ActiveStorage to trust the user-submitted content type rather than determining
    # it from the file contents, because Cellar does not seem to support the Range header
    #
    # FIXME : remove when better fix is available
    blob.update!(content_type: declared_content_type, identified: true) unless blob.identified?
  end
end
