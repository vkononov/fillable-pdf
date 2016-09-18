# FillablePDF

[![Gem Version](https://badge.fury.io/rb/fillable-pdf.svg)](https://rubygems.org/gems/fillable-pdf)

FillablePDF is an extremely simple and lightweight utility that bridges iText and Ruby in order to fill out fillable PDF forms or extract field values from previously filled out PDF forms. 


## Installation

Add this line to your application's Gemfile:

    gem 'fillable-pdf'

And then execute:

    bundle

Or install it yourself as:

    gem install fillable-pdf

If you are using this gem in a script, you need to require it manually:

```ruby
require 'fillable-xml'
```

## Usage

First of all, you should open a fillable PDF file:

```ruby
pdf = FillablePDF.new('input.pdf')
```

An instance of `FillablePDF` has the following methods at its disposal:

```ruby
pdf.has_fields? # returns true if the form has any fillable fields

pdf.num_fields # get the total number of fillable form fields

pdf.get_field('full_name') # retrieve a single field value by field name

pdf.set_field('first_name', 'Richard') # set a single field

pdf.set_fields({first_name: 'Richard', last_name: 'Rahl'}) # set multiple fields
```

Once the PDF is filled out you can either overwrite it or save it as another file:

```ruby
pdf.save

pdf.save_as('output.pdf')
```

Or if you prefer to flatten the file (i.e. make it non-editable), you can instead use:

```ruby
pdf.save(true)

pdf.save_as('output.pdf', true)
```


## Example

For a fuller usage example of this gem, please see the contents of the `test` directory.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).