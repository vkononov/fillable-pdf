
# FillablePDF

[![Gem Version](https://badge.fury.io/rb/fillable-pdf.svg)](https://rubygems.org/gems/fillable-pdf)
[![Build Status](https://api.travis-ci.org/vkononov/fillable-pdf.svg?branch=master)](http://travis-ci.org/vkononov/fillable-pdf)

FillablePDF is an extremely simple and lightweight utility that bridges iText and Ruby in order to fill out fillable PDF forms or extract field values from previously filled out PDF forms.

## Known Issues

If the gem hangs in `development`, removing the following gems may fix the issue:

```ruby
gem 'spring'
gem 'spring-watcher-listen'
```

If the gem hangs in `production`, you could try to use `puma` with a reverse proxy to host the application.


## Installation

**Ensure that your `JAVA_HOME` variable is set before installing this gem (see examples below).**

* OSX: `/Library/Java/JavaVirtualMachines/jdk-12.0.2.jdk/Contents/Home`
* Ubuntu/CentOS: `/usr/lib/jvm/java-1.8.0-openjdk`

Add this line to your application's Gemfile:

    ```ruby
    gem 'fillable-pdf'
	```

And then execute:

    bundle

Or install it yourself as:

    gem install fillable-pdf

If you are using this gem in a script, you need to require it manually:

```ruby
require 'fillable-pdf'
```

## Usage

First of all, you should open a fillable PDF file:

```ruby
pdf = FillablePDF.new 'input.pdf'
```

> **Always remember to close your document once you're finished working with it in order to avoid memory leaks:**

```ruby
pdf.close
```

### Checking / Unchecking Checkboxes

Use the values `'Yes'` and `'Off'` to check and uncheck checkboxes, respectively. For example:

    pdf.set_field(:newsletter, 'Yes')
    pdf.set_field(:newsletter, 'Off')

### Checking / Unchecking Radio Buttons

Suppose you have the following a radio button field name `language` with the following options:

  - Ruby (`ruby`)
  - Python (`python`)
  - Dart (`dart`)
  - Other (`other`)

To select one of these options (or change the current option) use:

    pdf.set_field(:language, 'dart')

To unset the radio button use the `'Off'` string:

    pdf.set_field(:language, 'Off')

### Instance Methods

An instance of `FillablePDF` has the following methods at its disposal:

* `any_fields?`
	*Determines whether the form has any fields.*
	```ruby
	pdf.any_fields?
	# output example: true
	```

* `num_fields`
	*Returns the total number of fillable form fields.*
	```ruby
	# output example: 10
	pdf.num_fields
	```

* `field`
	*Retrieves the value of a field given its unique field name.*
	```ruby
	pdf.field(:full_name)
	# output example: 'Richard'
	```

* `field_type`
	*Retrieves the numeric type of a field given its unique field name.*
	```ruby
	pdf.field_type(:football)
	# output example: '/Btn'

	# list of all field types
	Field::BUTTON ('/Btn')
	Field::CHOICE ('/Ch')
	Field::SIGNATURE ('/Sig')
	Field::TEXT ('/Tx')
	```

* `fields`
	*Retrieves a hash of all fields and their values.*
	```ruby
	pdf.fields
	# output example: {first_name: "Richard", last_name: "Rahl"}
	```

* `set_field`
	*Sets the value of a field given its unique field name and value.*
	```ruby
	pdf.set_field(:first_name, 'Richard')
	# result: changes the value of 'first_name' to 'Richard'
	```

* `set_fields`
	*Sets the values of multiple fields given a set of unique field names and values.*
	```ruby
	pdf.set_fields(first_name: 'Richard', last_name: 'Rahl')
	# result: changes the values of 'first_name' and 'last_name'
	```

* `rename_field`
	*Renames a field given its unique field name and the new field name.*
	```ruby
	pdf.rename_field(:last_name, :surname)
	# result: renames field name 'last_name' to 'surname'
	# NOTE: this action does not take effect until the document is saved
	```

* `remove_field`
	*Removes a field from the document given its unique field name.*
	```ruby
	pdf.remove_field(:last_name)
	# result: physically removes field 'last_name' from document
	```

* `names`
	*Returns a list of all field keys used in the document.*
	```ruby
	pdf.names
	# output example: [:first_name, :last_name]
	```

* `values`
	*Returns a list of all field values used in the document.*
	```ruby
	pdf.values
	# output example: ["Rahl", "Richard"]
	```

* `save`
	*Overwrites the previously opened PDF document and flattens it if requested.*
	```ruby
	pdf.save
	# result: document is saved without flatenning
	pdf.save_as(flatten: true)
	# result: document is saved with flatenning
	```

* `save_as`
	*Saves the filled out PDF document in a given path and flattens it if requested.*
	```ruby
	pdf.save_as('output.pdf')
	# result: document is saved in a given path without flatenning
	pdf.save_as('output.pdf', flatten: true)
	# result: document is saved in a given path with flatenning
	```

	**NOTE:** Saving the file automatically closes the input file, so you would need to reinitialize the `FillabePDF` class before making any more changes or saving another copy.

* `close`
	*Closes the PDF document discarding all unsaved changes.*
	```ruby
	pdf.close
	# result: document is closed
	```

## Example

The following example [example.rb](example/run.rb) and the input file [input.pdf](example/input.pdf) are located in the `test` directory. It uses all of the methods that are described above and generates the output files [output.pdf](example/output.pdf) and [output.flat.pdf](example/output.flat.pdf).

```ruby
require_relative '../lib/fillable-pdf'

# opening a fillable PDF
pdf = FillablePDF.new('input.pdf')

# total number of fields
if pdf.any_fields?
  puts "The form has a total of #{pdf.num_fields} fields."
else
  puts 'The form is not fillable.'
end

puts

# setting form fields
pdf.set_fields(first_name: 'Richard', last_name: 'Rahl')
pdf.set_fields(football: 'Yes', baseball: 'Yes',
               basketball: 'Yes', nascar: 'Yes', hockey: 'Yes')
pdf.set_field(:date, Time.now.strftime('%B %e, %Y'))
pdf.set_field(:newsletter, 'Off') # uncheck the checkbox
pdf.set_field(:language, 'dart') # select a radio button option

# list of fields
puts "Fields hash: #{pdf.fields}"

puts

# list of field names
puts "Keys: #{pdf.names}"

puts

# list of field values
puts "Values: #{pdf.values}"

puts

# Checking field type
if pdf.field_type(:football) == Field::BUTTON
  puts "Field 'football' is of type BUTTON"
else
  puts "Field 'football' is not of type BUTTON"
end

puts

# Renaming field
pdf.rename_field :last_name, :surname
puts "Renamed field 'last_name' to 'surname'"

puts

# Removing field
pdf.remove_field :nascar
puts "Removed field 'nascar'"
puts

# printing the name of the person used inside the PDF
puts "Signatory: #{pdf.field(:first_name)} #{pdf.field(:last_name)}"

# saving the filled out PDF in another file
pdf.save_as('output.pdf')

# saving another copy of the filled out PDF in another file and making it non-editable
pdf = FillablePDF.new('output.pdf')
pdf.save_as 'output.flat.pdf', flatten: true

# closing the document
pdf.close
```

The example above produces the following output and also generates the output file [output.pdf](example/output.pdf).

```
The form has a total of 14 fields.

Fields hash: {:last_name=>"Rahl", :first_name=>"Richard", :football=>"Yes", :baseball=>"Yes", :basketball=>"Yes", :hockey=>"Yes", :date=>"November 15, 2021", :newsletter=>"Off", :nascar=>"Yes", :language=>"dart", :"language.1"=>"dart", :"language.2"=>"dart", :"language.3"=>"dart", :"language.4"=>"dart"}

Keys: [:last_name, :first_name, :football, :baseball, :basketball, :hockey, :date, :newsletter, :nascar, :language, :"language.1", :"language.2", :"language.3", :"language.4"]

Values: ["Rahl", "Richard", "Yes", "Yes", "Yes", "Yes", "November 15, 2021", "Off", "Yes", "dart", "dart", "dart", "dart", "dart"]

Field 'football' is of type BUTTON

Renamed field 'last_name' to 'surname'

Removed field 'nascar'

Signatory: Richard Rahl
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

However, you must also adhere to the [iText License](https://github.com/itext/itext7) when using this gem in your project.