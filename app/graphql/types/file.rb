module Types
  class File < Types::BaseObject
    field :url, Types::URL, null: false
    field :filename, String, null: false
    field :byte_size, Int, null: false
    field :checksum, String, null: false
    field :content_type, String, null: false

    def url
      Rails.application.routes.url_helpers.url_for(object)
    end
  end
end
