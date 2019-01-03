describe NewAdministrateur::AdministrateurController, type: :controller do
  describe 'before actions: authenticate_administrateur!' do
    it 'is present' do
      before_actions = NewAdministrateur::AdministrateurController
        ._process_action_callbacks
        .find_all { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:authenticate_administrateur!)
    end
  end
end
