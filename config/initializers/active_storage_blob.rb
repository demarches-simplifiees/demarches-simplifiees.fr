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

    # see : https://docs.openstack.org/api-ref/object-store/?expanded=copy-object-detail
    # active storage open stack does not expose the copy method
    # but fog-openstack-1.0.11 does (a layer below)
    # copy_object
    #   def copy_object(source_container_name, source_object_name, target_container_name, target_object_name, options = {})
    #     ....
    #   end
    def migrate_to_prefixed_key
      old_key = key.dup
      new_key = ActiveStorage::Blob.make_prefixed_key(old_key)
      service.client.copy_object(source_container_name = service.container,
                                 source_object_name = old_key,
                                 target_container_name = service.container,
                                 new_key,
                                 headers = {"Content-Type" => self.content_type})
      update_columns(key: new_key, prefixed_key: true)
      service.delete(old_key)
    rescue Fog::OpenStack::Storage::NotFound
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
