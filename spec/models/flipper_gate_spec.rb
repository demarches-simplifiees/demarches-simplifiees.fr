# frozen_string_literal: true

describe Flipper::Adapters::ActiveRecord::Gate do
  describe 'validations' do
    it 'validates the presence of a ; in actors key' do
      expect {
        Flipper::Adapters::ActiveRecord::Gate.create!(feature_key: 'feature', key: 'actors', value: 'user1user2')
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect {
        Flipper::Adapters::ActiveRecord::Gate.create!(feature_key: 'feature', key: 'actors', value: 'User;123')
      }.not_to raise_error
    end
  end
end
