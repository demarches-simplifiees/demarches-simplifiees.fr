# frozen_string_literal: true

describe Exercice do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:ca) }
  end
end
