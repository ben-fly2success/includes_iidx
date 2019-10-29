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

    # @abstract Get the association of a class from its name
    # @return [ActiveRecord::Reflection]
    def self.association_for(klass, name)
      klass.reflect_on_all_associations.each do |a|
        return a if a.name == name
      end
      nil
    end

    # @abstract Get the klass pointed by an expection from its name
    # @return [<T>]
    def self.associated_klass_for(klass, name)
      association_for(klass, name)&.klass
    end

    # @abstract Resolve an DependenceSet in the context of a klass by replacing
    #           abstract elements (user-defined dependencies) by associations
    # @return [DependenceSet]
    def resolve_for(klass)
      res = IncludesIIDX::DependenceSet.empty

      # Resolve direct dependencies
      @direct.each do |d|
        if (attr_deps = klass.iidx_dependencies[d])
          res.merge!(attr_deps.resolve_for(klass))
        else
          if klass.respond_to?(:translated_attribute_names) && d.in?(klass.translated_attribute_names)
            res.direct |= [:translations]
          elsif IncludesIIDX::DependenceSet.association_for(klass, d)
            res.direct |= [d]
          end
        end
      end
      # Resolve association dependencies
      @associated.each do |k, v|
        res.associated[k] = if (sub = IncludesIIDX::DependenceSet.associated_klass_for(klass, k))
                              # Resolve associated klass if any
                              v.resolve_for(sub)
                            else
                              v
                            end
      end
      res
    end

    # @abstract Return an empty DependenceSet
    def self.empty
      new([])
    end
  end
end
