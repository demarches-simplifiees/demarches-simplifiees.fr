# frozen_string_literal: true

describe Logic::EmptyOperator do
  include Logic

  describe '#compute' do
    it { expect(empty_operator(empty, empty).compute).to be true }
  end
end
