module IncludesIIDX
  class ResolveDependencies
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
    def self.perform_for(klass, deps)
      res = IncludesIIDX::DependenceSet.empty

      # Resolve direct dependencies
      deps.direct.each do |d|
        if (attr_deps = klass.iidx_dependencies[d])
          res.merge!(perform_for(klass, attr_deps))
        else
          if klass.respond_to?(:translated_attribute_names) && d.in?(klass.translated_attribute_names)
            res.direct |= [:translations]
          elsif association_for(klass, d)
            res.direct |= [d]
          end
        end
      end
      # Resolve association dependencies
      deps.associated.each do |k, v|
        res.associated[k] = if (sub = associated_klass_for(klass, k))
                              # Resolve associated klass if any
                              perform_for(sub, v)
                            else
                              v
                            end
      end
      res
    end
  end
end
