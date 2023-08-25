describe AdminsGroupManagers::AdminsGroupManagerController, type: :controller do
  describe 'before actions: authenticate_admins_group_manager!' do
    it 'is present' do
      before_actions = AdminsGroupManagers::AdminsGroupManagerController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:authenticate_admins_group_manager!)
    end
  end
end
