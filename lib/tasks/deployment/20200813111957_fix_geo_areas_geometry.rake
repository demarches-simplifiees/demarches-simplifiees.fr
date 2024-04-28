# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_geo_areas_geometry'
  task fix_geo_areas_geometry: :environment do
    puts "Running deploy task 'fix_geo_areas_geometry'"

    geometry_collections = GeoArea.where("geometry -> 'type' = '\"GeometryCollection\"'")
    multi_polygons = GeoArea.where("geometry -> 'type' = '\"MultiPolygon\"'")
    multi_line_strings = GeoArea.where("geometry -> 'type' = '\"MultiLineString\"'")

    def valid_geometry?(geometry)
      RGeo::GeoJSON.decode(geometry.to_json, geo_factory: RGeo::Geographic.simple_mercator_factory)
      true
    rescue
      false
    end

    progress = ProgressReport.new(geometry_collections.count)
    geometry_collections.find_each do |geometry_collection|
      geometry_collection.geometry['geometries'].each do |geometry|
        if valid_geometry?(geometry)
          geometry_collection.champ.geo_areas.find_or_create_by!(geometry: geometry, source: 'selection_utilisateur')
        end
      end

      geometry_collection.destroy
      progress.inc
    end
    progress.finish

    progress = ProgressReport.new(multi_line_strings.count)
    multi_line_strings.find_each do |multi_line_string|
      multi_line_string.geometry['coordinates'].each do |coordinates|
        geometry = {
          type: 'LineString',
          coordinates: coordinates
        }

        if valid_geometry?(geometry)
          multi_line_string.champ.geo_areas.find_or_create_by!(geometry: geometry, source: 'selection_utilisateur')
        end
      end

      multi_line_string.destroy
      progress.inc
    end
    progress.finish

    progress = ProgressReport.new(multi_polygons.count)
    multi_polygons.find_each do |multi_polygon|
      multi_polygon.geometry['coordinates'].each do |coordinates|
        geometry = {
          type: 'Polygon',
          coordinates: coordinates
        }

        if valid_geometry?(geometry)
          multi_polygon.champ.geo_areas.find_or_create_by!(geometry: geometry, source: 'selection_utilisateur')
        end
      end

      multi_polygon.destroy
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
