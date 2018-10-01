class ProcedurePathFormatValidator < ActiveModel::Validator
  def path_regex
    /^[a-z0-9_]{3,30}$/
  end

  def validate(record)
    if record.path.blank?
      return false
    end

    if !path_regex.match(record.path)
      record.errors[:path] << "Path invalide"
    end
  end
end
