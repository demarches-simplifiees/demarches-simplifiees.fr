# references:
# https://evilmartians.com/chronicles/active-storage-meets-graphql-pt-2-exposing-attachment-urls

module Extensions
  class Attachment < GraphQL::Schema::FieldExtension
    attr_reader :attachment_assoc

    def apply
      # Here we try to define the attachment name:
      # - it could be set explicitly via extension options
      # - or we imply that is the same as the field name w/o "_url"
      # suffix (e.g., "avatar_url" => "avatar")
      attachment = options&.[](:attachment) || field.original_name.to_s.sub(/_url$/, "")

      # that's the name of the Active Record association
      @attachment_assoc = "#{attachment}_attachment"
    end

    # This method resolves (as it states) the field itself
    # (it's the same as defining a method within a type)
    def resolve(object:, **_rest)
      Loaders::Association.for(
        object.object.class,
        attachment_assoc => :blob
      ).load(object.object)
    end

    # This method is called if the result of the `resolve`
    # is a lazy value (e.g., a Promise – like in our case)
    def after_resolve(value:, **_rest)
      return if value.nil?

      Rails.application.routes.url_helpers.url_for(value)
    end
  end
end
