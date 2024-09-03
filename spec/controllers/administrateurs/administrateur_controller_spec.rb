# frozen_string_literal: true

describe Administrateurs::AdministrateurController, type: :controller do
  describe 'before actions: authenticate_administrateur!' do
    it 'is present' do
      before_actions = Administrateurs::AdministrateurController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:authenticate_administrateur!)
    end
  end
end
