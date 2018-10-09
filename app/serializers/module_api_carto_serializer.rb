class ModuleApiCartoSerializer < ActiveModel::Serializer
  attributes :use_api_carto,
    :quartiers_prioritaires,
    :cadastre,
    :parcelles_agricoles
end
