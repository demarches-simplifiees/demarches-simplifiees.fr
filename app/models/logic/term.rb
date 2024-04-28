# frozen_string_literal: true

class Logic::Term
  def to_json
    to_h.to_json
  end
end
