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

    def merge!(other)
      @direct |= other.direct
      @associated.merge!(other.associated)
    end

    def self.empty
      new([])
    end
  end
end
