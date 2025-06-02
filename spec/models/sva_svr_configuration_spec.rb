# frozen_string_literal: true

require 'rails_helper'

describe SVASVRConfiguration, type: :model do
  subject(:sva_svr_config) do
    SVASVRConfiguration.new(
      decision: decision,
      period: period,
      unit: unit,
      resume: resume
    )
  end

  let(:decision) { 'disabled' }
  let(:period) { 2 }
  let(:unit) { 'months' }
  let(:resume) { 'continue' }

  describe 'validations' do
    context 'when decision is "disabled"' do
      it 'is valid even if period, unit and resume are nil' do
        sva_svr_config.period = nil
        sva_svr_config.unit = nil
        sva_svr_config.resume = nil

        expect(sva_svr_config).to be_valid
      end
    end

    context 'when decision is not in DECISION_OPTIONS' do
      let(:decision) { 'invalid_decision' }

      it 'is not valid' do
        expect(sva_svr_config).not_to be_valid
      end
    end

    context 'when decision is not "disabled"' do
      let(:decision) { 'sva' }

      it { expect(sva_svr_config).to be_valid }

      it 'is not valid if period is nil' do
        sva_svr_config.period = nil

        expect(sva_svr_config).not_to be_valid
      end

      it 'is not valid if unit is nil or not in UNIT_OPTIONS' do
        sva_svr_config.unit = nil

        expect(sva_svr_config).not_to be_valid

        sva_svr_config.unit = 'years'

        expect(sva_svr_config).not_to be_valid
      end

      it 'is not valid if resume is nil or not in RESUME_OPTIONS' do
        sva_svr_config.resume = nil

        expect(sva_svr_config).not_to be_valid

        sva_svr_config.resume = 'pause'

        expect(sva_svr_config).not_to be_valid
      end

      it 'is not valid if period is not an integer' do
        sva_svr_config.period = 3.14

        expect(sva_svr_config).not_to be_valid
      end
    end
  end
end
