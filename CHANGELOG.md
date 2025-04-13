## [Unreleased]

## [0.1.1] - 2025-04-13

### Added

- `Castkit::Attribute#dataobject_collection?`

  A new helper method that returns `true` if the attribute is an array of `Castkit::DataObject` instances.
  This is determined by checking if the attribute's type is `:array` and the `:of` option is a Castkit::DataObject class.

  ```ruby
  attribute = Castkit::Attribute.new(:comments, :array, of: CommentDto)
  attribute.dataobject_collection? # => true
  ```

  Useful when working with nested DataObject collections (e.g., for integration with ActiveRecord or serialization logic).

## [0.1.0] - 2025-04-12

- Initial release
