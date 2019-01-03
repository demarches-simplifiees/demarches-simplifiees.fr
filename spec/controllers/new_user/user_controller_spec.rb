require 'spec_helper'

describe NewUser::UserController, type: :controller do
  describe 'before actions: authenticate_gestionnaire!' do
    it 'is present' do
      before_actions = NewUser::UserController
        ._process_action_callbacks
        .find_all { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:authenticate_user!)
    end
  end
end
