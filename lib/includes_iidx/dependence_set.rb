module IncludesIIDX
  class DependenceSet
    attr_accessor :direct
    attr_accessor :associated

    def initialize(combined)
      @direct = []
      @associated = {}
      case combined.class.name
      when 'Array'
        combined.each do |a|
          case a.class.name
          when 'Symbol'
            @direct << a
          when 'Hash'
            a.each do |k, v|
              # Deep recursive initialization, all subsets are converted to DependenceSets
              @associated[k] = IncludesIIDX::DependenceSet.new(v)
            end
          else
            raise "Dependence type not handled: #{a.class.name} (valid types are Symbol, Hash)"
          end
        end
      when 'Symbol'
        @direct << combined
      when 'Hash'
        combined.each do |k, v|
          @associated[k] = IncludesIIDX::DependenceSet.new(v)
        end
      else
        raise "Dependence type not: handled: #{combined.class.name} (valid types are Symbol, Hash)"
      end
    end

    # @abstract Convert the DependenceSet to an array, possibly terminated by an hash
    # @note The output format is the one used by ActiveRecord `includes` scope
    # @return [Array]
    def to_a
      copy = dup
      res = []
      res += copy.direct
      copy.associated.each do |k, v|
        copy.associated[k] = v.to_a
      end
      res.push(copy.associated) unless copy.associated.empty?
      res
    end

    # @abstract Merge two DependenceSets
    def merge!(other)
      @direct |= other.direct
      @associated.merge!(other.associated)
    end

    # @abstract Return an empty DependenceSet
    def self.empty
      new([])
    end
  end
end
