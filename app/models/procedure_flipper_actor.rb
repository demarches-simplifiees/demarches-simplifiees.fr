# frozen_string_literal: true

# Use this when we want to check feature flags on a procedure whithout loading the all procedure
class ProcedureFlipperActor < Struct.new(:procedure_id) do
    def flipper_id
      "Procedure;#{procedure_id}"
    end
  end
end
