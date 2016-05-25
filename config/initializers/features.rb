require 'yaml'
# this class manage features
# Features must be added in file config/initializers/features.yml :
# feature_name: true
# other_feature: false
#
# this file is templated by ansible for staging and production so don't forget to add your features in
# ansible config
class Features
  class << self
    if File.exist?(File.dirname(__FILE__) + '/features.yml')
      features_map = YAML.load_file(File.dirname(__FILE__) + '/features.yml')
      if features_map
        features_map.each do |feature, is_active|
          define_method("#{feature}") do
            is_active
          end
        end
      end

      def method_missing(method, *args)
        false
      end
    end
  end
end
