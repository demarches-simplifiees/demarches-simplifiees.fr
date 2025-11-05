# frozen_string_literal: true

class StepperBaseComponent < ViewComponent::Base
  attr_reader :step_component

  def initialize(step_component:)
    @step_component = step_component
  end

  def back_link
    raise NotImplementedError
  end

  def title
    raise NotImplementedError
  end

  def step_title
    raise NotImplementedError
  end

  def next_step_title
    nil
  end

  def current_step
    raise NotImplementedError
  end

  def step_count
    raise NotImplementedError
  end

  def step_state
    "Étape #{current_step} sur #{step_count}"
  end
end
