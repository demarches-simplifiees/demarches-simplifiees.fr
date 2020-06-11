if ENV.fetch('RBTRACE_ENABLED', 'false') == 'true'
  require 'rbtrace'
  require 'objspace'
  ObjectSpace.trace_object_allocations_start
end
