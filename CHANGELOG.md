## [Unreleased]

## [0.2.0] - 2025-04-14

### Added

- **First-class Type System via `Castkit::Types`**:
  - Introduced a formalized type system under `Castkit::Types`, where each primitive type (e.g., `:string`, `:integer`, `:boolean`) is represented by a class.
  - Each type class implements `.deserialize`, `.serialize`, `.validate!`, and `.cast!`, allowing for strict control over coercion, validation, and extension.
  - Developers may register custom types via `Castkit.configure`:

    ```ruby
    class CustomType < Castkit::Types::Generic
      def deserialize(value) ... end
      def validate!(value, **) ... end
    end

    Castkit.configure do |config|
      config.register_type :custom, CustomType
    end
    ```

- **New DSL for Building Contracts**:
  - Added `Castkit::Contract.build`, a lightweight DSL for defining and validating structured input without requiring a full `DataObject`.
  - Useful for validating inputs to services, operations, or external APIs.

    ```ruby
    UserContract = Castkit::Contract.build do
      string :id
      string :name, required: false
    end

    result = UserContract.validate(id: "123")
    result.success? # => true
    ```

  - Contracts support:
    - Primitive and nested `DataObject` types
    - Optional fields, format, and type union support
    - Strict/relaxed validation with unknown attribute handling
    - Structured validation result via `Castkit::Contract::Result`

- **Union type validation support** for both `Castkit::DataObject` and contracts, allowing attributes to accept multiple types (e.g., `[:string, :integer]`).

## [0.1.2] - 2025-04-14

### Added

- **`allow_unknown` Configuration in `Castkit::DataObject`**:
  - Introduced a new configuration option, `allow_unknown`, which controls whether unknown attributes during deserialization are allowed.
  - If `allow_unknown` is set to `true`, unknown attributes will be captured and included in the object's `unknown_attributes` hash.
  - If `allow_unknown` is set to `false`, unknown attributes will either raise an error or log a warning based on the `strict` configuration.
  - If `allow_unknown` is enabled, it overrides the `strict` setting, disabling strict validation for unknown keys.

  ```ruby
  class UserDto < Castkit::DataObject
    allow_unknown true
    string :id
  end
  
  user = UserDto.new(id: 123, name: 'Castkit')
  user.to_h # { id: 123, name: 'Castkit' }
  ```
- **`enable_warnings` Configuration flag in `Castkit.configure`**:
  - Added a new flag `enable_warnings` to the `Castkit.configure` block, which controls whether warnings (such as those for unknown attributes) are emitted.
  - Defaults to `true`, enabling warnings by default. Set to `false` to suppress warnings globally.

  ```ruby
  Castkit.configure do |config|
    config.enable_warnings = false
  end
  ```

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
