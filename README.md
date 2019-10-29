# includes_iidx

A simple gem helping you building `includes` scopes to load dependent associations, thus keeping constant-complexity queries.

### Usage example

Just indicate dependencies as following:

```rb
def Parent
  def full_name
    parent_column_attribute
  end
  set_dependencies_for :full_name, :parent_column_attribute
end

def Child
  belongs_to :parent

  def full_name
    "#{parent.full_name}: #{child_column_attribute}"
  end
  set_dependencies_for :full_name, [:model_attribute, parent: :full_name]
end
```

Then when it comes to display a collection of `Child`, normally you would do :

```rb
Child.all.map(&:full_name) # Results in an N + 1 query
```

To prevent the N + 1 query, use the following scope :

```rb
Child.all.includes_iidx(:full_name).map(&:full_name) # Constant query. Yay !
```
For each requested attribute passed to `includes_iidx`, all dependent models will be included.

### Gem compatibility

Globalize is automatically supported. You can put a translated attribute in a set of dependancies, when requested the `translations` association will be loaded.
