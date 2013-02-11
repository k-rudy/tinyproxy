require 'objspace'

module TinyProxy
  module Space
    # Calculates cache space required to store given arguments
    #
    def space_needed_for(*args)
      args.inject(0) { |sum, arg| sum += ObjectSpace.memsize_of(arg) }
    end
  end
end
