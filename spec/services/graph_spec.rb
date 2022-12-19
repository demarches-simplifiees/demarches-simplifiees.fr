describe 'possibles_branches' do
  include Logic

  # should produce the simpliest verson
  # of a condition
  def canonic(condition)
    return condition if condition.class != Logic::And

    ds_and = condition

    canonical_predicats = ds_and
      .operands
      .group_by(&:class)
      .values.map do |predicats|
        case predicats.first
        in Logic::GreaterThan | Logic::GreaterThanEq
          canonic_greater(predicats)
        in Logic::LessThan | Logic::LessThanEq
          canonic_less(predicats)
        in Logic::Constant
          canonic_constant(predicats)
        end
      end
      .then { merge_greater(_1) }
      .then { merge_less(_1) }

    case canonical_predicats
    in [one]
      one
    in _ if false?(canonical_predicats)
      constant(false)
    else
      ds_and(canonical_predicats)
    end
  end

  # ... && false == false
  # x < 1 && x > 3 == false
  def false?(predicats)
    if predicats.count == 1
      return true if predicats.first == constant(false)
      return false
    end

    return true if predicats.include?(constant(false))

    greater_than = predicats.find { |o| o.class == Logic::GreaterThan }&.right&.value
    greater_than_eq = predicats.find { |o| o.class == Logic::GreaterThanEq }&.right&.value

    lesser_than = predicats.find { |o| o.class == Logic::LessThan }&.right&.value
    lesser_than_eq = predicats.find { |o| o.class == Logic::LessThanEq }&.right&.value

    # TODO canonical should return in max  only one of (> or >=) and one of (< or =<)
    # TODO test
    (lesser_than || lesser_than_eq) < (greater_than || greater_than_eq)
  end

  # false && false == false
  def canonic_constant(constants)
    constant(constants.map(&:value).all?)
  end

  # x > 1 && x > 3 == x > 3
  # x >= 1 && x >= 3 == x >= 3
  def canonic_greater(greaters)
    klass = greaters.first.class
    left = greaters.first.left
    max = greaters.map(&:right).max
    klass.new(left, max)
  end

  # x < 1 && x < 3 == x < 1
  def canonic_less(less)
    klass = less.first.class
    left = less.first.left
    min = less.map(&:right).min
    klass.new(left, min)
  end

  # TODO x > 3 && x >= 3 => x >= 3
  def merge_greater(predicats)
    predicats
  end

  #
  # TODO x < 3 && x <= 3 =< x < 3
  def merge_less(predicats)
    predicats
  end

  describe 'canonic' do
    let(:gt_1) { greater_than(champ_value(1), constant(1)) }
    let(:gt_3) { greater_than(champ_value(1), constant(3)) }

    let(:ls_1) { less_than(champ_value(1), constant(1)) }
    let(:ls_3) { less_than(champ_value(1), constant(3)) }

    it do
      # case without condition
      expect(canonic(nil)).to eq(nil)

      expect(canonic(constant(true))).to eq(constant(true))
      expect(canonic(gt_1)).to eq(gt_1)

      expect(canonic(ds_and([gt_1, gt_3]))).to eq(gt_3)
      expect(canonic(ds_and([ls_1, ls_3]))).to eq(ls_1)
      expect(canonic(ds_and([gt_1, ls_3]))).to eq(ds_and([gt_1, ls_3]))
      expect(canonic(ds_and([gt_3, constant(false)]))).to eq(constant(false))
      expect(canonic(ds_and([constant(true), constant(true)]))).to eq(constant(true))

      expect(canonic(ds_and([gt_3, ls_1]))).to eq(constant(false))
    end
  end

  def not_predicat(predicat)
    case predicat
    in Logic::GreaterThan
      less_than_eq(predicat.left, predicat.right)
    else
      raise "not predicat not coded for #{predicat.class.name}"
    end
  end

  class Branch < Struct.new(:tdcs, :conditions)
  end

  def possibles_branches(tdcs)
    tdcs
      .each { |tdc| tdc.condition = canonic(tdc.condition) }
      .reject! { |tdc| tdc.condition == constant(false) }

    without_conditions, with_conditions = tdcs.partition { _1.condition.nil? || _1.condition == constant(true) }

    branches = [Branch.new(without_conditions, [])]

    while !with_conditions.empty?
      tdc = with_conditions.shift
      branches = branches.flat_map do |branch|
        if should_be_duplicate?(branch, tdc)

          new_branch = Branch.new(branch.tdcs + [tdc], branch.conditions + [tdc.condition])
          branch.conditions << not_predicat(tdc.condition)

          [branch, new_branch]
        else
          [branch]
        end
      end
    end

    branches.map { |b| b.tdcs.map(&:stable_id) }
  end

  def should_be_duplicate?(branch, tdc)
    !false?(Array.wrap(canonic(ds_and(branch.conditions + [tdc.condition]))))
  end

  describe 'possibles_branches' do
    let(:gt_1) { greater_than(champ_value(1), constant(1)) }
    let(:gt_3) { greater_than(champ_value(1), constant(3)) }

    let(:ls_1) { less_than(champ_value(1), constant(1)) }
    let(:ls_3) { less_than(champ_value(1), constant(3)) }

    let(:tdc_1) { build(:type_de_champ, stable_id: 1) }
    let(:tdc_2) { build(:type_de_champ, condition: ds_and([constant(true), constant(true)]), stable_id: 2) }
    let(:tdc_3) { build(:type_de_champ, condition: ds_and([constant(true), constant(false)]), stable_id: 3) }

    let(:tdc_4) { build(:type_de_champ, condition: gt_1, stable_id: 4) }
    let(:tdc_5) { build(:type_de_champ, condition: gt_3, stable_id: 5) }

    it do
      expect(possibles_branches([tdc_1, tdc_2, tdc_3])).to eq([[1, 2]])
      expect(possibles_branches([tdc_1, tdc_4])).to eq([[1], [1, 4]])

      expect(possibles_branches([tdc_1, tdc_4, tdc_5])).to eq([
        [1], # 0
        [1, 4], # 2
        [1, 4, 5] # 5
      ])
    end
  end
end
