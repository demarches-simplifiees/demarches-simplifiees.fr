# frozen_string_literal: true

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
          # Unsaved: built from the unverified demandeur SIRET by DossierType#demandeur
          if object.new_record? && context.has_fragment?(:PersonneMoraleIncomplete)
            Types::PersonneMoraleIncompleteType
          else
            Types::PersonneMoraleType
          end
        end
      end
    end
  end
end
