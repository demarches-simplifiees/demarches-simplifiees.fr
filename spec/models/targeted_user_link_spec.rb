# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TargetedUserLink, type: :model do
  describe 'Validation' do
    let(:targeted_user_link) { build(:targeted_user_link) }

    describe 'target_context' do
      it 'is bullet proof' do
        expect { targeted_user_link.target_context = :kc }.to raise_error(ArgumentError, "'kc' is not a valid target_context")
      end
    end
  end
end
