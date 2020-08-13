namespace :after_party do
  desc 'Deployment task: fix_geo_areas_geometry'
  task fix_geo_areas_geometry: :environment do
    puts "Running deploy task 'fix_geo_areas_geometry'"

    geometry_collections = GeoArea.where("geometry -> 'type' = '\"GeometryCollection\"'")
    multi_polygons = GeoArea.where("geometry -> 'type' = '\"MultiPolygon\"'")

    geometry_collections.find_each do |geometry_collection|
      geometry_collection.geometry['geometries'].each do |geometry|
        geometry_collection.champ.geo_areas.create!(geometry: geometry, source: 'selection_utilisateur')
      end
    end

    multi_polygons.find_each do |multi_polygon|
      multi_polygon.geometry['coordinates'].each do |coordinates|
        multi_polygon.champ.geo_areas.create!(geometry: {
          type: 'Polygon',
          coordinates: coordinates
        }, source: 'selection_utilisateur')
      end
    end

    geometry_collections.destroy_all
    multi_polygons.destroy_all

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
