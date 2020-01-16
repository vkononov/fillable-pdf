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