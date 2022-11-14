Rails.application.config.to_prepare do
  require 'active_storage/blob'
  ActiveStorage::Blob.class_eval do

    before_create :set_prefixed_key, if: :prefixed_key?

    def set_prefixed_key
      self.prefixed_key = true
    end

    def prefixed_key?
      ENV['OBJECT_STORAGE_BLOB_PREFIXED_KEY'].present?
    end


    class << self
      def generate_unique_secure_token(length: MINIMUM_TOKEN_LENGTH)
        if ENV['OBJECT_STORAGE_BLOB_PREFIXED_KEY'].present?
          make_prefixed_key(super(length: length))
        else
          super(length: length)
        end
      end

      def make_prefixed_key(key)
        [segment, key].join('/')
      end

      def segment
        [rand_a_to_z, rand_a_to_z].join('')
      end

      def rand_a_to_z
        ('a'..'z').to_a.sample
      end
    end
  end
end
