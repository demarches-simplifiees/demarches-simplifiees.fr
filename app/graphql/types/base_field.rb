# frozen_string_literal: true

module Types
  class BaseField < GraphQL::Schema::Field
    def initialize(*args, internal: false, **kwargs, &block)
      @internal = internal
      super(*args, **kwargs, &block)
    end

    def visible?(context)
      super && visible_unless_internal?(context) && visible_unless_deprecated?(context)
    end

    private

    def visible_unless_internal?(context)
      if @internal
        context[:internal_use]
      else
        true
      end
    end

    def visible_unless_deprecated?(context)
      if name == "options" && owner.name == 'Types::ChampDescriptorType'
        !context.has_fragments?([:PaysChampDescriptor, :RegionChampDescriptor, :DepartementChampDescriptor])
      else
        true
      end
    end
  end
end
