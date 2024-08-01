# frozen_string_literal: true

describe Gestionnaires::GestionnaireController, type: :controller do
  describe 'before actions: authenticate_gestionnaire!' do
    it 'is present' do
      before_actions = Gestionnaires::GestionnaireController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:authenticate_gestionnaire!)
    end
  end
end
