module ActiveStorage
  # activestorage-openstack uses ActiveStorage::FileNotFoundError which only exists in rails 6
  class FileNotFoundError < StandardError; end
end
