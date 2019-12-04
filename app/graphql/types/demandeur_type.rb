module Types
  module DemandeurType
    include Types::BaseInterface

    global_id_field :id

    definition_methods do
      def resolve_type(object, context)
        case object
        when Individual
          Types::PersonnePhysiqueType
        when Etablissement
          Types::PersonneMoraleType
        end
      end
    end
  end
end
