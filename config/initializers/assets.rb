# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# prevent random crashes when building docker (pf)
# https://stackoverflow.com/questions/66927024/cant-push-to-heroku-sassc-segmentation-fault
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add some node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules', 'ol')
Rails.application.config.assets.paths << Rails.root.join('node_modules', 'trix', 'dist')
Rails.application.config.assets.paths << Rails.root.join('node_modules', 'mapbox-gl', 'dist')
Rails.application.config.assets.paths << Rails.root.join('node_modules', '@reach', 'combobox')
Rails.application.config.assets.paths << Rails.root.join('node_modules', '@mapbox', 'mapbox-gl-draw', 'dist')
Rails.application.config.assets.paths << Rails.root.join('node_modules', '@gouvfr', 'dsfr', 'dist', 'artwork')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
