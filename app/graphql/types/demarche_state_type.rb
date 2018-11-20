module Types
  class DemarcheStateType < Types::BaseEnum
    Procedure.aasm.states.each do |state|
      value(state.name.to_s, state.display_name, value: state.name)
    end
  end
end
