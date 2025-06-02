# frozen_string_literal: true

describe Users::UserController, type: :controller do
  describe 'before actions: authenticate_instructeur!' do
    it 'is present' do
      before_actions = Users::UserController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:authenticate_user!)
    end
  end
end
