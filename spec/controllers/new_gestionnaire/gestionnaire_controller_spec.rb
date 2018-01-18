require 'spec_helper'

describe NewGestionnaire::GestionnaireController, type: :controller do
  describe 'before actions: authenticate_gestionnaire!' do
    it 'is present' do
      before_actions = NewGestionnaire::GestionnaireController
        ._process_action_callbacks
        .find_all{ |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:authenticate_gestionnaire!)
    end
  end
end
