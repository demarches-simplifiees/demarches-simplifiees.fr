# frozen_string_literal: true

class FalsifyOpendataService
  def self.call(lines)
    errors = []
    lines.each do |line|
      id = line["id"]
      procedure = Procedure.find_by(id: id)
      if procedure
        procedure.update(opendata: false)
      else
        errors << "Procedure #{id} introuvable"
      end
    end
    errors
  end
end
