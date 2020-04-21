describe Instructeurs::InstructeurController, type: :controller do
  describe 'before actions: authenticate_instructeur!' do
    it 'is present' do
      before_actions = Instructeurs::InstructeurController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:authenticate_instructeur!)
    end
  end
end
