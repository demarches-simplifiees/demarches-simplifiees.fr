module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
    private

    def load_application_object(arg_kwarg, id)
      super(arg_kwarg, id_with_type(arg_kwarg, id))
    end

    def id_with_type(type, id)
      case type
      when :dossier
        Dossier.new(id: id).to_typed_id
      else
        id
      end
    end
  end
end
