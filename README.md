
# Castkit

**Castkit** is a lightweight, type-safe Ruby DSL for defining and validating data objects.

It’s inspired by DTO (data transfer object) patterns and brings clarity, safety, and structure to how you define and manipulate structured data in Ruby — with support for casting, validation, access control, serialization, and extensibility.

---

## ✨ Features

- ✅ Declarative type-safe attribute definitions
- 🔁 Built-in casting for primitive and custom types
- 🔍 Pluggable validation (with per-type default validators)
- 🔐 Attribute-level access control (`read`, `write`)
- 📦 Serialization and deserialization with optional unwrapping and root keys
- ♻️ Circular reference detection during serialization
- 🔧 Configurable enforcement and custom validators

---

## 🔧 Installation

Add this line to your Gemfile:

```ruby
gem 'castkit'
```

Then install:

```bash
bundle install
```

Or install manually:

```bash
gem install castkit
```

---

## 🚀 Quick Start

```ruby
class UserDto < Castkit::DataObject
  string :name
  integer :age, required: false
  boolean :admin, default: false

  unwrapped :profile, ProfileDto, prefix: "profile_"
end

user = UserDto.new(name: "Alice", age: 30, profile_name: "Dev")
user.to_h
# => { name: "Alice", age: 30, admin: false, profile_name: "Dev" }

user.to_json
# => '{"name":"Alice","age":30,"admin":false,"profile_name":"Dev"}'
```

---

## 🧱 Defining Attributes

| Type        | Example                        |
|-------------|--------------------------------|
| `string`    | `string :name`                 |
| `integer`   | `integer :age`                 |
| `boolean`   | `boolean :active`              |
| `float`     | `float :rating`                |
| `date`      | `date :published_on`           |
| `datetime`  | `datetime :created_at`         |
| `array`     | `array :tags, of: :string`     |
| `hash`      | `hash :metadata`               |
| `dataobject`| `dataobject :profile, ProfileDto` |

---

## 🧪 Validation

Validators can be built-in or custom:

```ruby
class ZipValidator
  def call(value, options:, context:)
    raise Castkit::AttributeError, "#{context} is not a valid ZIP" unless value =~ /^\d{5}$/
  end
end

class AddressDto < Castkit::DataObject
  string :zip, validator: ZipValidator.new
end
```

You can also register per-type defaults globally:

```ruby
Castkit.configuration.register_validator(:zip, ZipValidator.new)
```

---

## 🔐 Access Control

```ruby
class CredentialsDto < Castkit::DataObject
  string :username
  string :password, access: [:write]  # only writeable, not serialized
end
```

---

## 🪄 Serialization Options

- `ignore_nil: true` – skip nils
- `ignore_blank: true` – skip `[]`, `{}`, `""`, etc.
- `unwrapped: true, prefix: "foo_"` – flatten nested objects
- `root "user"` – wrap in `{ "user": { ... } }`

---

## 🔄 Custom Serializers

```ruby
class SimpleSerializer < Castkit::Serializer
  private

  def call
    obj.class.attributes.keys.map { |k| [k, obj.public_send(k)] }.to_h
  end
end

class EventDto < Castkit::DataObject
  string :type
  string :timestamp

  serializer SimpleSerializer
end
```

---

## ⚙️ Configuration

```ruby
Castkit.configuration.enforce_array_of_type = true
Castkit.configuration.enforce_boolean_casting = false
Castkit.configuration.register_validator(:uuid, UuidValidator.new)

Castkit.configure do |config|
  config.enforce_array_of_type = true
end
```

---

## 💥 Error Handling

- `Castkit::AttributeError` – invalid attribute value
- `Castkit::DataObjectError` – object-level failure (e.g., unknown key)
- `Castkit::SerializationError` – circular reference or serialization failure

---

## 🧪 Testing

You can test DTOs by instantiating them like POROs:

```ruby
dto = MyDto.new(input_data)
expect(dto.name).to eq("expected")
```

---

## 📦 Compatibility

- Ruby 2.7+
- Zero dependencies (uses core Ruby)

---

## 📃 License

MIT. See [LICENSE](LICENSE).

---

## 🙏 Credits

Created with ❤️ by [Nathan Lucas](https://github.com/you)  
Inspired by Java DTOs, dry-rb, and the need for clean, reliable data structures in APIs.
