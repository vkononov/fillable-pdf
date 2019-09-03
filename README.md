# FillablePDF

[![Gem Version](https://badge.fury.io/rb/fillable-pdf.svg)](https://rubygems.org/gems/fillable-pdf)
[![Build Status](https://api.travis-ci.org/vkononov/fillable-pdf.svg?branch=master)](http://travis-ci.org/vkononov/fillable-pdf)

FillablePDF is an extremely simple and lightweight utility that bridges iText and Ruby in order to fill out fillable PDF forms or extract field values from previously filled out PDF forms. 

## Installation

**Ensure that your `JAVA_HOME` variable is set before installing this gem (see examples below).**
 
* OSX: `/Library/Java/JavaVirtualMachines/jdk-12.0.2.jdk/Contents/Home`  
* Ubuntu/CentOS: `/usr/lib/jvm/java-1.8.0-openjdk`

Add this line to your application's Gemfile:

    gem 'fillable-pdf'

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

An instance of `FillablePDF` has the following methods at its disposal:

```ruby
fillable-pdf
# output example: true
pdf.any_fields?
```

```ruby
# get the total number of fillable form fields
# output example: 10
pdf.num_fields
```

```ruby
# retrieve a single field value by field name
# output example: 'Richard'
pdf.field(:full_name)
```

```ruby
# retrieve a field type by field name
# numeric types should 
# output example: 4
pdf.field_type(:football)

# list of all field types
Field::BUTTON
Field::CHOICE
Field::SIGNATURE
Field::TEXT
```

```ruby
# retrieve a hash of field name and values
# output example: {:last_name=>"Rahl", :first_name=>"Richard"}
pdf.fields
```

```ruby
# set the value of a single field by field name
# result: changes the value of 'first_name' to 'Richard'
pdf.set_field(:first_name, 'Richard')
```

```ruby
# set the values of multiple fields by field names
# result: changes the values of 'first_name' and 'last_name'
pdf.set_fields(first_name: 'Richard', last_name: 'Rahl')
```

```ruby
# rename field (i.e. change the name of the field)
# result: renames field name 'last_name' to 'surname'
# NOTE: this action does not take effect until the document is saved 
pdf.rename_field(:last_name, :surname)
```

```ruby
# remove field (i.e. delete field and its value)
# result: physically removes field 'last_name' from document
pdf.remove_field(:last_name)
```

```ruby
# get an array of all field names in the document
# output example: [:first_name, :last_name]
pdf.names
```

```ruby
# get an array of all field values in the document
# output example: ["Rahl", "Richard"]
pdf.values
```

Once the PDF is filled out you can either overwrite it or save it as another file:

```ruby
pdf.save
pdf.save_as('output.pdf')
```

Or if you prefer to flatten the file (i.e. make it non-editable), you can instead use:

```ruby
pdf.save(flatten: true)
pdf.save_as('output.pdf', flatten: true)
```

**NOTE:** Saving the file automatically closes the input file, so you would need to reinitialize the `FillabePDF` class before making any more changes or saving another copy. 

## Example

The following example [example.rb](example/run.rb) and the input file [input.pdf](example/input.pdf) are located in the `test` directory. It uses all of the methods that are described above and generates the output files [output.pdf](example/output.pdf) and [output.flat.pdf](example/output.flat.pdf).

```ruby
require 'fillable-pdf'

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
```

The example above produces the following output and also generates the output file [output.pdf](example/output.pdf).

```
The form has a total of 8 fields.

Fields hash: {:last_name=>"Rahl", :first_name=>"Richard", :football=>"Yes", :baseball=>"Yes", :basketball=>"Yes", :nascar=>"Yes", :hockey=>"Yes", :date=>"August 30, 2019"}

Keys: [:last_name, :first_name, :football, :baseball, :basketball, :nascar, :hockey, :date]

Values: ["Rahl", "Richard", "Yes", "Yes", "Yes", "Yes", "Yes", "August 30, 2019"]

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
