# Castkit

Castkit is a lightweight, type-safe data object system for Ruby. It provides a declarative DSL for defining data transfer objects (DTOs) with built-in support for typecasting, validation, nested data structures, serialization, deserialization, and contract-driven programming.

Inspired by tools like Jackson (Java) and Python dataclasses, Castkit brings structured data modeling to Ruby in a way that emphasizes:

- **Simplicity**: Minimal API surface and predictable behavior.
- **Explicitness**: Every field and type is declared clearly.
- **Composition**: Support for nested objects, collections, and modular design.
- **Performance**: Fast and efficient with minimal runtime overhead.
- **Extensibility**: Easy to extend with custom types, serializers, and integrations.

Castkit is designed to work seamlessly in service-oriented and API-driven architectures, providing structure without overreach.

---

## 🚀 Features

- [Configuration](#configuration)
- [Attribute DSL](#attribute-dsl)
- [DataObjects](#dataobjects)
- [Contracts](#contracts)
- [Advance Usage](#advanced-usage-coming-soon)
- [Plugins](#plugins)
- [Castkit CLI](#castkit-cli)
- [Testing](#testing)
- [Compatibility](#compatibility)
- [License](#license)

---

## Configuration

Castkit provides a global configuration interface to customize behavior across the entire system. You can configure Castkit by passing a block to `Castkit.configure`.

```ruby
Castkit.configure do |config|
  config.enable_warnings = false
  config.enforce_typing = true
end
```

### ⚙️ Available Settings

| Option                      | Type    | Default | Description |
|----------------------------|---------|---------|-------------|
| `enable_warnings`          | Boolean | `true`  | Enables runtime warnings for misconfigurations. |
| `enforce_typing`           | Boolean | `true`  | Raises if type mismatch during load (e.g., `true` vs. `"true"`). |
| `enforce_attribute_access` | Boolean | `true`  | Raises if an unknown access level is defined. |
| `enforce_unwrapped_prefix` | Boolean | `true`  | Requires `unwrapped: true` when using attribute prefixes. |
| `enforce_array_options`    | Boolean | `true`  | Raises if an array attribute is missing the `of:` option. |
| `raise_type_errors`        | Boolean | `true`  | Raises if an unregistered or invalid type is used. |
| `strict_by_default`        | Boolean | `true`  | Applies `strict: true` by default to all DTOs and Contracts. |

### 🔧 Type System

Castkit comes with built-in support for primitive types and allows registration of custom ones:

#### Default types

```ruby
{
        array: Castkit::Types::Collection,
        boolean: Castkit::Types::Boolean,
        date: Castkit::Types::Date,
        datetime: Castkit::Types::DateTime,
        float: Castkit::Types::Float,
        hash: Castkit::Types::Base,
        integer: Castkit::Types::Integer,
        string: Castkit::Types::String
}
```

#### Type Aliases

| Alias      | Canonical |
|------------|-----------|
| `collection` | `array`   |
| `bool`       | `boolean` |
| `int`        | `integer` |
| `map`        | `hash`    |
| `number`     | `float`   |
| `str`        | `string`  |
| `timestamp`  | `datetime`|
| `uuid`       | `string`  |

#### Registering Custom Types

```ruby
Castkit.configure do |config|
  config.register_type(:mytype, MyTypeClass, aliases: [:custom])
end
```

---

## Attribute DSL

Castkit attributes define the shape, type, and behavior of fields on a DataObject. Attributes are declared using the `attribute` method or shorthand type methods provided by `Castkit::Core::AttributeTypes`.

```ruby
class UserDto < Castkit::DataObject
  string :name, required: true
  boolean :admin, default: false
  array :tags, of: :string, ignore_nil: true
end
```

---

### 🧠 Supported Types

Castkit supports a strict set of primitive types defined in `Castkit::Configuration::DEFAULT_TYPES` and aliased in `TYPE_ALIASES`.

#### Canonical Types:
- `:array`
- `:boolean`
- `:date`
- `:datetime`
- `:float`
- `:hash`
- `:integer`
- `:string`

#### Type Aliases:

Castkit provides shorthand aliases for common primitive types:

| Alias        | Canonical   | Description                         |
|--------------|-------------|-------------------------------------|
| `collection` | `array`     | Alias for arrays                    |
| `bool`       | `boolean`   | Alias for true/false types          |
| `int`        | `integer`   | Alias for integer values            |
| `map`        | `hash`      | Alias for hashes (key-value pairs)  |
| `number`     | `float`     | Alias for numeric values            |
| `str`        | `string`    | Alias for strings                   |
| `timestamp`  | `datetime`  | Alias for date-time values          |
| `uuid`       | `string`    | Commonly used for identifiers       |

No other types are supported unless explicitly registered via `Castkit.configuration.register_type`.

---


### ⚙️ Attribute Options

| Option            | Type       | Default       | Description |
|-------------------|------------|----------------|-------------|
| `required`        | Boolean    | `true`         | Whether the field is required on initialization. |
| `default`         | Object/Proc| `nil`          | Default value or lambda called at runtime. |
| `access`          | Array<Symbol> | `[:read, :write]` | Controls read/write visibility. |
| `ignore_nil`      | Boolean    | `false`        | Exclude `nil` values from serialization. |
| `ignore_blank`    | Boolean    | `false`        | Exclude empty strings, arrays, and hashes. |
| `ignore`          | Boolean    | `false`        | Fully ignore the field (no serialization/deserialization). |
| `composite`       | Boolean    | `false`        | Used for computed, virtual fields. |
| `transient`       | Boolean    | `false`        | Excluded from serialized output. |
| `unwrapped`       | Boolean    | `false`        | Merges nested DataObject fields into parent. |
| `prefix`          | String     | `nil`          | Used with `unwrapped` to prefix keys. |
| `aliases`         | Array<Symbol> | `[]`         | Accept alternative keys during deserialization. |
| `of:`             | Symbol     | `nil`          | Required for `:array` attributes. |
| `validator:`      | Proc       | `nil`          | Optional callable that validates the value. |

---

### 🔒 Access Control

Access determines when the field is considered readable/writable.

```ruby
string :email, access: [:read]
string :password, access: [:write]
```

---

### 🧩 Attribute Grouping

Castkit supports grouping attributes using `required` and `optional` blocks to reduce repetition and improve clarity when defining large DTOs.

#### Example

```ruby
class UserDto < Castkit::DataObject
  required do
    string :id
    string :name
  end

  optional do
    integer :age
    boolean :admin
  end
end
```

This is equivalent to:

```ruby
class UserDto < Castkit::DataObject
  string :id # required: true
  string :name # required: true
  integer :age, required: false
  boolean :admin, required: false
end
```
Grouped declarations are especially useful when your DTO has many optional fields or a mix of required/optional fields across different types.

---

### 🧬 Unwrapped & Composite

```ruby
class Metadata < Castkit::DataObject
  string :locale
end

class PageDto < Castkit::DataObject
  dataobject :metadata, Metadata, unwrapped: true, prefix: "meta"
end

# Serializes as:
# { "meta_locale": "en" }
```

#### Composite Attributes

Composite fields are computed virtual attributes:

```ruby
class ProductDto < Castkit::DataObject
  string :name, required: true
  string :sku, access: [:read]
  float :price, default: 0.0

  composite :description, :string do
    "#{name}: #{sku} - #{price}"
  end
end
```

---

### 🔍 Transient Attributes

Transient fields are excluded from serialization and can be defined in two ways:

```ruby
class ProductDto < Castkit::DataObject
  string :id, transient: true

  transient do
    string :internal_token
  end
end
```

---

### 🪞 Aliases and Key Paths

```ruby
string :email, aliases: ["emailAddress", "user.email"]

dto.load({ "emailAddress" => "foo@bar.com" })
```

---

### 🧪 Example

```ruby
class ProductDto < Castkit::DataObject
  string :name, required: true
  float :price, default: 0.0, validator: ->(v) { raise "too low" if v < 0 }
  array :tags, of: :string, ignore_blank: true
  string :sku, access: [:read]

  composite :description, :string do
    "#{name}: #{sku} - #{price}"
  end

  transient do
    string :id
  end
end
```

---

## DataObjects

`Castkit::DataObject` is the base class for all structured DTOs. It offers a complete lifecycle for data ingestion, transformation, and output, supporting strict typing, validation, access control, aliasing, serialization, and root-wrapped payloads.

---

### ✍️ Defining a DTO

```ruby
class UserDto < Castkit::DataObject
  string :id
  string :name
  integer :age, required: false
end
```

---

### 🚀 Instantiation & Usage

```ruby
user = UserDto.new(name: "Alice", age: 30)
user.to_h       #=> { name: "Alice", age: 30 }
user.to_json    #=> '{"name":"Alice","age":30}'
```

---

### ⚖️ Strict Mode vs. Unknown Key Handling

By default, Castkit operates in strict mode and raises if unknown keys are passed. You can override this:

```ruby
class LooseDto < Castkit::DataObject
  strict false
  ignore_unknown true      # equivalent to strict false
  warn_on_unknown true     # emits a warning instead of raising
end
```

To build a relaxed version dynamically:

```ruby
LooseClone = MyDto.relaxed(warn_on_unknown: true)
```

---

### 🧱 Root Wrapping

```ruby
class WrappedDto < Castkit::DataObject
  root :user
  string :name
end

WrappedDto.new(name: "Test").to_h
#=> { "user" => { "name" => "Test" } }
```

---

### 📦 Deserialization Helpers

You can deserialize using:

```ruby
UserDto.from_h(hash)
UserDto.deserialize(hash)
```

---

### 🔁 Conversion from/to Contract

```ruby
contract = UserDto.to_contract
UserDto.validate!(id: "123", name: "Alice")

from_contract = Castkit::DataObject.from_contract(contract)
```

---

### 🔄 Serializer Override

To override default serialization behavior:

```ruby

class CustomSerializer < Castkit::Serializers::Base
  def call
    { payload: object.to_h }
  end
end

class MyDto < Castkit::DataObject
  string :field
  serializer CustomSerializer
end
```

---

### 🔍 Tracking Unknown Fields

```ruby
dto = UserDto.new(name: "Alice", foo: "bar")
dto.unknown_attributes
#=> { foo: "bar" }
```

---

### 📤 Registering a Contract

```ruby
UserDto.register!(as: :User)
# Registers under Castkit::DataObjects::User
```

---

## Contracts

`Castkit::Contract` provides a lightweight mechanism for validating structured input without requiring a full data model. Ideal for validating service inputs, API payloads, or command parameters.

---

### 🛠 Defining Contracts

You can define a contract using the `.build` DSL:

```ruby
UserContract = Castkit::Contract.build(:user) do
  string :id
  string :email, required: false
end
```

Or subclass directly:

```ruby

class MyContract < Castkit::Contract::Base
  string :id
  integer :count, required: false
end
```

---

### 🧪 Validation

```ruby
UserContract.validate(id: "123")
UserContract.validate!(id: "123")
```

Returns a `Castkit::Contract::Result` with:

- `#success?` / `#failure?`
- `#errors` hash
- `#to_h` / `#to_s`

---

### ⚖️ Strict, Loose, and Warn Modes

```ruby
LooseContract = Castkit::Contract.build(:loose, strict: false) do
  string :token
end

StrictContract = Castkit::Contract.build(:strict, allow_unknown: false, warn_on_unknown: true) do
  string :id
end
```

---

### 🔄 Converting From DataObject

```ruby
class UserDto < Castkit::DataObject
  string :id
  string :email
end

UserContract = Castkit::Contract.from_dataobject(UserDto)
```

---

### ↔️ Converting Back to DTO

```ruby
UserDto = UserContract.to_dataobject
# or
UserDto = UserContract.dataobject
```

---

### 📤 Registering a Contract

```ruby
UserContract.register!(as: :UserInput)
# Registers under Castkit::Contracts::UserInput
```

---

### 🧱 Supported Options in Contract Attributes

Only a subset of options are supported:

- `required`
- `aliases`
- `min`, `max`, `format`
- `of` (for arrays)
- `validator`
- `unwrapped`, `prefix`
- `force_type`

---

### 🧩 Validating Nested DTOs

```ruby
class AddressDto < Castkit::DataObject
  string :city
end

class UserDto < Castkit::DataObject
  string :id
  dataobject :address, AddressDto
end

UserContract = Castkit::Contract.from_dataobject(UserDto)
UserContract.validate!(id: "abc", address: { city: "Boston" })
```

---

## Advanced Usage (coming soon)

Castkit is designed to be modular and extendable. Future guides will cover:

- Custom serializers (`Castkit::Serializers::Base`)
- Integration layers:
    - `castkit-activerecord` for syncing with ActiveRecord models
    - `castkit-msgpack` for binary encoding
    - `castkit-oj` for high-performance JSON
- OpenAPI-compatible schema generation
- Declarative enums and union type helpers
- Circular reference detection in nested serialization

---

## Plugins

Castkit supports modular extensions through a lightweight plugin system. Plugins can modify or extend the behavior of `Castkit::DataObject` classes, such as adding serialization support, transformation helpers, or framework integrations.

Plugins are just Ruby modules and can be registered and activated globally or per-class.

---

### 📦 Activating Plugins

Plugins can be activated on any DataObject or at runtime:

```ruby
module MyPlugin
  def self.setup!(klass)
    # Optional: called after inclusion
    klass.string :plugin_id
  end

  def plugin_feature
    "Enabled!"
  end
end

Castkit.configure do |config|
  config.register_plugin(:my_plugin, MyPlugin)
end

class MyDto < Castkit::DataObject
  enable_plugins :my_plugin
end
```

This includes the `MyPlugin` module into `MyDto` and calls `MyPlugin.setup!(MyDto)` if defined.

---

### 🧩 Registering Plugins

Plugins must be registered before use:

```ruby
Castkit.configure do |config|
  config.register_plugin(:oj, Castkit::Plugins::Oj)
end
```

You can then activate them:

```ruby
Castkit::Plugins.activate(MyDto, :oj)
```

Or by using the `enable_plugins` helper method in `Castkit::DataObject`:

```ruby
class MyDto < Castkit::DataObject
  enable_plugins :oj, :yaml
end
```

---

### 🧰 Plugin API

| Method                        | Description |
|------------------------------|-------------|
| `Castkit::Plugins.register(:name, mod)` | Registers a plugin under a custom name. |
| `Castkit::Plugins.activate(klass, *names)` | Includes one or more plugins into a class. |
| `Castkit::Plugins.lookup!(:name)`        | Looks up the plugin by name or constant. |

---

### 📁 Plugin Structure

Castkit looks for plugins under the `Castkit::Plugins` namespace by default:

```ruby
module Castkit
  module Plugins
    module Oj
      def self.setup!(klass)
        klass.include SerializationSupport
      end
    end
  end
end
```

To activate this:

```ruby
Castkit::Plugins.activate(MyDto, :oj)
```

You can also manually register plugins not under this namespace.

---

### ✅ Example Use Case

```ruby
module Castkit
  module Plugins
    module Timestamps
      def self.setup!(klass)
        klass.datetime :created_at
        klass.datetime :updated_at
      end
    end
  end
end

Castkit::Plugins.activate(UserDto, :timestamps)
```

This approach allows reusable, modular feature sets across DTOs with clean setup behavior.

---

## Castkit CLI

Castkit includes a command-line interface to help scaffold and inspect DTO components with ease.

The CLI is structured around two primary commands:

- `castkit generate` — scaffolds boilerplate for Castkit components.
- `castkit list` — introspects and displays registered or defined components.

---

## ✨ Generate Commands

The `castkit generate` command provides subcommands for creating files for all core Castkit component types.

### 🧱 DataObject

```bash
castkit generate dataobject User name:string age:integer
```

Creates:

- `lib/castkit/data_objects/user.rb`
- `spec/castkit/data_objects/user_spec.rb`

### 📄 Contract

```bash
castkit generate contract UserInput id:string email:string
```

Creates:

- `lib/castkit/contracts/user_input.rb`
- `spec/castkit/contracts/user_input_spec.rb`

### 🔌 Plugin

```bash
castkit generate plugin Oj
```

Creates:

- `lib/castkit/plugins/oj.rb`
- `spec/castkit/plugins/oj_spec.rb`

### 🧪 Validator

```bash
castkit generate validator Money
```

Creates:

- `lib/castkit/validators/money.rb`
- `spec/castkit/validators/money_spec.rb`

### 🧬 Type

```bash
castkit generate type money
```

Creates:

- `lib/castkit/types/money.rb`
- `spec/castkit/types/money_spec.rb`

### 📦 Serializer

```bash
castkit generate serializer Json
```

Creates:

- `lib/castkit/serializers/json.rb`
- `spec/castkit/serializers/json_spec.rb`

You can disable test generation with `--no-spec`.

---

## 📋 List Commands

The `castkit list` command provides an interface to view internal Castkit definitions or project-registered components.

### 🧾 List Types

```bash
castkit list types
```

Displays a grouped list of:

- Native types (defined by Castkit)
- Custom types (registered via `Castkit.configure`)

Example:

```bash
Native Types:
  Castkit::Types::String         - :string, :str, :uuid

Custom Types:
  MyApp::Types::Money            - :money
```

### 🔍 List Validators

```bash
castkit list validators
```

Displays all validator classes defined in `lib/castkit/validators` or custom-defined under `Castkit::Validators`.

Castkit validators are tagged `[Castkit]`, and others as `[Custom]`.

### 📑 List Contracts

```bash
castkit list contracts
```

Lists all contracts in the `Castkit::Contracts` namespace and related files.

### 📦 List DataObjects

```bash
castkit list dataobjects
```

Lists all DTOs in the `Castkit::DataObjects` namespace.

### 🧪 List Serializers

```bash
castkit list serializers
```

Lists all serializer classes and their source origin.

---

## 🧰 Example Usage

```bash
castkit generate dataobject Product name:string price:float
castkit generate contract ProductInput name:string

castkit list types
castkit list validators
```

The CLI is designed to provide a familiar Rails-like generator experience, tailored for Castkit’s data-first architecture.

---

## Testing

You can test DTOs and Contracts by treating them like plain Ruby objects:

```ruby
dto = MyDto.new(name: "Alice")
expect(dto.name).to eq("Alice")
```

You can also assert validation errors:

```ruby
expect {
  MyDto.new(name: nil)
}.to raise_error(Castkit::AttributeError, /name is required/)
```

---

## Compatibility

- Ruby 2.7+
- Zero dependencies (uses core Ruby)

---

## License

MIT. See [LICENSE](LICENSE).

---

## 🙏 Credits

Created with ❤️ by [Nathan Lucas](https://github.com/bnlucas)
