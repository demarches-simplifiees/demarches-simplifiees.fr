# Adapted from https://github.com/thirtysixthspan/descriptive_statistics

# Copyright (c) 2010-2014 Derrick Parkhurst (derrick.parkhurst@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

class Array
  def percentile(p)
    values = self.sort

    if values.empty?
      return []
    elsif values.size == 1
      return values.first
    elsif p == 100
      return values.last
    end

    rank = p / 100.0 * (values.size - 1)
    lower, upper = values[rank.floor, 2]
    lower + (upper - lower) * (rank - rank.floor)
  end
end
