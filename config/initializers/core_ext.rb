# frozen_string_literal: true

Rails.root.glob('lib/core_ext/*.rb').each do |core_ext_file|
  require core_ext_file
end
