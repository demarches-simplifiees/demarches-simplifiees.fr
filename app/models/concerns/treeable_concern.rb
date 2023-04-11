module TreeableConcern
  extend ActiveSupport::Concern

  MAX_DEPTH = 6 # deepest level for header_sections is 3.
  # but a repetition can be nested an header_section, so 3+3=6=MAX_DEPTH

  included do
    # as we progress in the list of ordered champs
    #   we keep a reference to each level of nesting (depth_cache)
    # when we encounter an header_section, it depends of its own depth of nesting minus 1, ie:
    #   h1 belongs to prior (root)
    #   h2 belongs to prior h1
    #   h3 belongs to prior h2
    #   h1 belongs to prior (root)
    # then, each and every champs which are not an header_section
    #   are added to the most_recent_subtree
    # given a root_depth at 0, we build a full tree
    # given a root_depth > 0, we build a partial tree (aka, a repetition)
    def to_tree(champs:, root_depth:)
      root = []
      depth_cache = Array.new(MAX_DEPTH)
      depth_cache[root_depth] = root
      most_recent_subtree = root

      champs.each do |champ|
        if champ.header_section?
          champs_subtree = [champ]
          depth_cache[champ.level - 1].push(champs_subtree)
          most_recent_subtree = depth_cache[champ.level] = champs_subtree
        else
          most_recent_subtree.push(champ)
        end
      end
      root
    end
  end
end
