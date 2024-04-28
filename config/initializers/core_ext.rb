# frozen_string_literal: true

Dir[Rails.root.join("lib", "core_ext", "*.rb")].each do |core_ext_file|
  require core_ext_file
end
