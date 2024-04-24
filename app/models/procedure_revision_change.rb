class ProcedureRevisionChange
  class TypeDeChangeChange
    attr_reader :type_de_champ
    def initialize(type_de_champ)
      @type_de_champ = type_de_champ
    end

    def label = @type_de_champ.libelle
    def stable_id = @type_de_champ.stable_id
    def private? = @type_de_champ.private?
    def child? = @type_de_champ.child?

    def to_h = { op:, stable_id:, label:, private: private? }
  end

  class AddChamp < TypeDeChangeChange
    def initialize(type_de_champ)
      super(type_de_champ)
    end

    def op = :add
    def mandatory? = @type_de_champ.mandatory?
    def can_rebase?(dossier = nil) = !mandatory?

    def to_h = super.merge(mandatory: mandatory?)
  end

  class RemoveChamp < TypeDeChangeChange
    def initialize(type_de_champ)
      super(type_de_champ)
    end

    def op = :remove
    def can_rebase?(dossier = nil) = true
  end

  class MoveChamp < TypeDeChangeChange
    attr_reader :from, :to

    def initialize(type_de_champ, from, to)
      super(type_de_champ)
      @from = from
      @to = to
    end

    def op = :move
    def can_rebase?(dossier = nil) = true
    def to_h = super.merge(from:, to:)
  end

  class UpdateChamp < TypeDeChangeChange
    attr_reader :attribute, :from, :to

    def initialize(type_de_champ, attribute, from, to)
      super(type_de_champ)
      @attribute = attribute
      @from = from
      @to = to
    end

    def op = :update
    def to_h = super.merge(attribute:, from:, to:)

    def can_rebase?(dossier = nil)
      return true if private?
      case attribute
      when :drop_down_options
        (from - to).empty? || dossier&.can_rebase_drop_down_options_change?(stable_id, from - to)
      when :drop_down_other
        !from && to
      when :mandatory
        (from && !to) || dossier&.can_rebase_mandatory_change?(stable_id)
      when :type_champ, :condition, :expression_reguliere
        false
      else
        true
      end
    end
  end

  class TransitionsRulesChange
    attr_reader :previous_revision, :new_revision
    def initialize(previous_revision, new_revision)
      @previous_revision = previous_revision
      @new_revision = new_revision
      @previous_transitions_rules = @previous_revision.transitions_rules
      @new_transitions_rules = @new_revision.transitions_rules
    end

    def previous_condition
      @previous_transitions_rules&.to_s(previous_revision.types_de_champ.filter { @previous_transitions_rules.sources.include? _1.stable_id })
    end

    def new_condition
      @new_transitions_rules&.to_s(new_revision.types_de_champ.filter { @new_transitions_rules.sources.include? _1.stable_id })
    end
  end

  class AddTransitionsRule < TransitionsRulesChange
    def op = :add
  end

  class RemoveTransitionsRule < TransitionsRulesChange
    def op = :remove
  end

  class ChangeTransitionsRule < TransitionsRulesChange
    def op = :update
  end
end
