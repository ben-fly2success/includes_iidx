module IncludesIIDX
  class DependenceSet
    attr_accessor :deps

    def initialize(combined)
      @deps = {}
      if combined.class.name != 'Array'
        combined = [combined]
      end
      combined.each do |a|
        case a.class.name
        when 'Symbol'
          @deps[a] = IncludesIIDX::DependenceSet.empty
        when 'Hash'
          a.each do |k, v|
            # Deep recursive initialization, all subsets are converted to DependenceSets
            @deps[k] = IncludesIIDX::DependenceSet.new(v)
          end
        else
          raise "Dependence type not handled: #{a.class.name} (valid types are Symbol, Hash)"
        end
      end
    end

    # @abstract Convert the DependenceSet to an array, possibly terminated by an hash
    # @note The output format is the one used by ActiveRecord `includes` scope
    # @return [Array]
    def to_a
      direct = []
      associated = {}
      @deps.each do |k, v|
        if v.empty?
          direct << k
        else
          associated[k] = v.to_a
        end
      end
      direct + (associated.any? ? [associated] : [])
    end

    # @abstract Merge two DependenceSets
    def merge!(other)
      @deps.deep_merge!(other.deps)
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
      if asso = association_for(klass, name)
        if asso.polymorphic?
          :polymorphic
        else
          asso.klass
        end
      end
    end

    # @abstract Resolve an DependenceSet in the context of a klass by replacing
    #           abstract elements (user-defined dependencies) by associations
    # @return [DependenceSet]
    def resolve_for(klass)
      res = IncludesIIDX::DependenceSet.empty

      @deps.each do |k, v|
        if (sub = IncludesIIDX::DependenceSet.associated_klass_for(klass, k))
          res.deps[k] = sub == :polymorphic ? {} : v.resolve_for(sub)
        end
        if (attr_deps = klass.iidx_dependencies[k])
          res.merge!(attr_deps.resolve_for(klass))
        end
        if klass.respond_to?(:translated_attribute_names) && k.in?(klass.translated_attribute_names)
          res.merge!(IncludesIIDX::DependenceSet.new([:translations]))
        end
      end
      res
    end

    def empty?
      deps.empty?
    end

    # @abstract Return an empty DependenceSet
    def self.empty
      new([])
    end
  end
end
