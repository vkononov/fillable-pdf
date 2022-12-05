
# FillablePDF

[![Gem Version](https://badge.fury.io/rb/fillable-pdf.svg)](https://rubygems.org/gems/fillable-pdf)
[![Test Status](https://github.com/vkononov/fillable-pdf/actions/workflows/test.yml/badge.svg)](https://github.com/vkononov/fillable-pdf/actions)

FillablePDF is an extremely simple and lightweight utility that bridges iText and Ruby in order to fill out fillable PDF forms or extract field values from previously filled out PDF forms.

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png)](https://www.buymeacoffee.com/vkononov)

## Known Issues

1. Phusion Passenger's [smart spawning](https://www.phusionpassenger.com/library/indepth/ruby/spawn_methods/#the-smart-spawning-method) is not supported. Please see [Deployment with Phusion Passenger + Nginx](#deployment-with-phusion-passenger--nginx) for more information.

2. Puma workers (process forking) is not supposed due to an [issue](https://github.com/arton/rjb/issues/88) with the [rjb](https://github.com/arton/rjb) gem dependency.

3. If the gem hangs in `development`, removing the following gems may fix the issue:

    ```ruby
    gem 'spring'
    gem 'spring-watcher-listen'
    ```

4. Read-only, write-protected or encrypted PDF files are currently not supported.

5. Adobe generated field arrays (i.e. fields with names such as `array.0` or `array.1.0`) are not supported.


## Troubleshooting Issues

### Blank Fields

* **Actual Result:**

  ![Blank](images/blank.png)

* **Expected Result:**

  ![Blank](images/checked.png)

If all of the fields are blank, try setting the `generate_appearance` flag to `true` when calling `set_field` or `set_fields`.

### Invalid Checkbox Appearances

* **Actual Result:**

  ![Blank](images/checked.png)

* **Expected Result:**

  ![Blank](images/distinct.png)

If your checkboxes are showing incorrectly, it's likely because iText is overwriting your checkbox appearances. Try setting the `generate_appearance` flag to `false` when calling `set_field` or `set_fields`.

## Installation

**Prerequisites:** Java SE Development Kit v8, v11

- Ensure that your `JAVA_HOME` variable is set before installing this gem (see examples below).

  * OSX: `/Library/Java/JavaVirtualMachines/jdk-11.0.2.jdk/Contents/Home`
  * Ubuntu/CentOS: `/usr/lib/jvm/java-1.8.0-openjdk`

Add this line to your application's Gemfile:

```ruby
gem 'fillable-pdf'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install fillable-pdf
```

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

```ruby
pdf.set_field(:newsletter, 'Yes')
pdf.set_field(:newsletter, 'Off')
```

### Checking / Unchecking Radio Buttons

Suppose you have the following a radio button field name `language` with the following options:

  - Ruby (`ruby`)
  - Python (`python`)
  - Dart (`dart`)
  - Other (`other`)

To select one of these options (or change the current option) use:

```ruby
pdf.set_field(:language, 'dart')
```

To unset the radio button use the `'Off'` string:

```ruby
pdf.set_field(:language, 'Off')
```

### Adding Signatures or Images

Digital signatures are not supported, but you can place an image or a base64 encoded image within the bounds of any form field.

SVG images are not supported. You will have to convert them to a JPG or PNG first.

See methods `set_image` and `set_image_base64` below.

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

* `field(key)`
    *Retrieves the value of a field given its unique field name.*

    ```ruby
    pdf.field(:full_name)
    pdf.field('full_name')
    # output example: 'Richard'
    ```

* `field_type(key)`
    *Retrieves the string type of a field given its unique field name.*

    ```ruby
    pdf.field_type(:football)
    pdf.field_type('football')
    # output example: '/Btn'

    # list of all field types
    Field::BUTTON ('/Btn')
    Field::CHOICE ('/Ch')
    Field::SIGNATURE ('/Sig')
    Field::TEXT ('/Tx')
    ```

    You can check the field type by using:

    ```ruby
    pdf.field_type(:football) == Field::BUTTON
    pdf.field_type('football') == Field::BUTTON
    ```

* `fields`
    *Retrieves a hash of all fields and their values.*

    ```ruby
    pdf.fields
    # output example: {first_name: "Richard", last_name: "Rahl"}
    ```

* `set_field(key, value, generate_appearance: nil)`
    *Sets the value of a field given its unique field name and value, with an optional `generate_appearance` directive.*

    ```ruby
    pdf.set_field(:first_name, 'Richard')
    pdf.set_field('first_name', 'Richard')
    # result: changes the value of 'first_name' to 'Richard'
    ```

  Optionally, you can choose to override iText's `generateAppearance` flag to take better control of your field's appearance, using `generate_appearance`. Passing `true` will force the field to generate its own appearance, while setting it to `false` would leave the appearance generation up to the PDF viewer application. Omitting the parameter would allow iText to decide what should happen.

    ```ruby
    pdf.set_field(:first_name, 'Richard', generate_appearance: true)
    pdf.set_field('first_name', 'Richard', generate_appearance: false)
    ```

* `def set_fields(fields, generate_appearance: nil)`
    *Sets the values of multiple fields given a set of unique field names and values, with an optional `generate_appearance` directive.*

    ```ruby
    pdf.set_fields({first_name: 'Richard', last_name: 'Rahl'})
    # result: changes the values of 'first_name' and 'last_name'
    ```

  Optionally, you can choose to override iText's `generateAppearance` flag to take better control of your fields' appearance, using `generate_appearance`. Passing `true` will force the field to generate its own appearance, while setting it to `false` would leave the appearance generation up to the PDF viewer application. Omitting the parameter would allow iText to decide what should happen.

    ```ruby
    pdf.set_fields({first_name: 'Richard', last_name: 'Rahl'}, generate_appearance: true)
    pdf.set_fields({first_name: 'Richard', last_name: 'Rahl'}, generate_appearance: false)
    ```

* `set_image(key, file_path)`
  *Places an image file within the rectangular bounding box of the given form field.*

    ```ruby
    pdf.set_image(:signature, 'signature.png')
    pdf.set_image('signature', 'signature.png')
    # result: the image 'signature.png' is shown in the foreground of the form field
    ```

* `set_image_base64(key, base64_image_data)`
  *Places a base64 encoded image within the rectangular bounding box of the given form field.*

    ```ruby
    pdf.set_image_base64('signature', 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==')
    pdf.set_image_base64(:signature, 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==')
    # result: the base64 encoded image is shown in the foreground of the form field
    ```

* `rename_field(old_key, new_key)`
    *Renames a field given its unique field name and the new field name.*

    ```ruby
    pdf.rename_field(:last_name, :surname)
    pdf.rename_field('last_name', 'surname')
    # result: renames field name 'last_name' to 'surname'
    # NOTE: this action does not take effect until the document is saved
    ```

* `remove_field(key)`
    *Removes a field from the document given its unique field name.*

    ```ruby
    pdf.remove_field(:last_name)
    pdf.remove_field('last_name')
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

* `save(flatten: false)`
    *Overwrites the previously opened PDF document and flattens it if requested.*

    ```ruby
    pdf.save
    # result: document is saved without flattening
    pdf.save_as(flatten: true)
    # result: document is saved with flattening
    ```

* `save_as(file_path, flatten: false)`
    *Saves the filled out PDF document in a given path and flattens it if requested.*

    ```ruby
    pdf.save_as('output.pdf')
    # result: document is saved in a given path without flattening
    pdf.save_as('output.pdf', flatten: true)
    # result: document is saved in a given path with flattening
    ```

    **NOTE:** Saving the file automatically closes the input file, so you would need to reinitialize the `FillabePDF` class before making any more changes or saving another copy.

* `close`
    *Closes the PDF document discarding all unsaved changes.*

    ```ruby
    pdf.close
    # result: document is closed
    ```


## Deployment with Heroku

When deploying to Heroku, be sure to install the following build packs (in this order):

```bash
heroku buildpacks:add heroku/jvm
heroku buildpacks:add heroku/ruby
```

## Deployment with Phusion Passenger + Nginx

The way the gem is currently built makes it [fundamentally incompatible](https://github.com/phusion/passenger/issues/223#issuecomment-44504029) with Phusion Passenger's [smart spawning](https://www.phusionpassenger.com/library/indepth/ruby/spawn_methods/#the-smart-spawning-method). You must turn off smart spawning, or else your application will freeze as soon Ruby tries to access the Java bridge.

Below is an example of a simple Nginx virtual host configuration (note the use of `passenger_spawn_method`):

```nginx
server {
    server_name my-rails-app.com;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    passenger_enabled on;
    passenger_spawn_method direct;
    root /home/system/my-rails-app/public;
}
```

If you absolutely must have smart spawning, I recommend using `fillable-pdf` as a service that runs independently of your Rails application.

## Deployment with Puma + Nginx

In order to use Puma in production, you need to configure a reverse proxy in your Nginx virtual host. Here is simple naive example:

```nginx
server {
    server_name my-rails-app.com;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    location / {
        proxy_pass http://127.0.0.1:8888;
        proxy_redirect off;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Then you'll have to start Puma in production daemon mode as follows:

```bash
RAILS_ENV=production bin/rails server -p 8888 --daemon
```

Naturally, there are many downsides (in terms of efficiency, scalability, security, etc) to running your application in production in this manner, so please use the above as an example only.


## Example

The following [example.rb](example/run.rb) with [input.pdf](example/input.pdf) is located in the [example](example) directory. It uses all of the methods that are described above and generates the output files [output.pdf](example/output.pdf) and [output.flat.pdf](example/output.flat.pdf).

```ruby
require_relative '../lib/fillable-pdf'

BASE64_PHOTO = 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' # rubocop:disable Layout/LineLength

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
pdf.set_fields({first_name: 'Richard', last_name: 'Rahl'})
pdf.set_fields({football: 'Yes', baseball: 'Yes', basketball: 'Yes', nascar: 'Yes', hockey: 'Yes', rugby: 'Yes'}, generate_appearance: false)
pdf.set_field(:date, Time.now.strftime('%B %e, %Y'))
pdf.set_field(:newsletter, 'Off') # uncheck the checkbox
pdf.set_field(:language, 'dart') # select a radio button option
pdf.set_image_base64(:photo, BASE64_PHOTO)
pdf.set_image(:signature, 'signature.png')

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
if pdf.field_type(:rugby) == Field::BUTTON
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
pdf.remove_field :marketing
puts "Removed field 'marketing'"

# saving the filled out PDF in another file
pdf.save_as('output.pdf')

# saving another copy of the filled out PDF in another file and making it non-editable
pdf = FillablePDF.new('output.pdf')
pdf.save_as 'output.flat.pdf', flatten: true

# closing the document
pdf.close
```

The example above produces the following output and also generates the output file [output.pdf](example/output.pdf).

```text
The form has a total of 16 fields.

Fields hash: {:last_name=>"Rahl", :first_name=>"Richard", :football=>"Yes", :baseball=>"Yes", :basketball=>"Yes", :hockey=>"Yes", :date=>"November 16, 2021", :newsletter=>"Off", :nascar=>"Yes", :language=>"dart", :"language.1"=>"dart", :"language.2"=>"dart", :"language.3"=>"dart", :"language.4"=>"dart", :signature=>"", :photo=>""}

Keys: [:last_name, :first_name, :football, :baseball, :basketball, :hockey, :date, :newsletter, :nascar, :language, :"language.1", :"language.2", :"language.3", :"language.4", :signature, :photo]

Values: ["Rahl", "Richard", "Yes", "Yes", "Yes", "Yes", "November 16, 2021", "Off", "Yes", "dart", "dart", "dart", "dart", "dart", "", ""]

Field 'football' is of type BUTTON

Renamed field 'last_name' to 'surname'

Removed field 'nascar'
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