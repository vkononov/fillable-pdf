require_relative 'support/pdf_test_base'

class PdfImageTest < PdfTestBase
  def test_that_an_image_can_be_placed_in_signature_field
    assert @pdf.set_image(:signature, 'test/files/signature.png')
  end

  def test_that_a_base64_can_be_placed_in_photo_field
    assert @pdf.set_image_base64(:photo, @base64)
  end

  def test_set_image_base64_with_tempfile
    Tempfile.create(['image', '.png']) do |_temp|
      image_data = Base64.strict_encode64(File.read('test/files/signature.png'))
      @pdf.set_image_base64(:signature, image_data)

      assert @pdf.set_image_base64(:signature, image_data)
    end
  end

  def test_set_image_with_invalid_path
    err = assert_raises IOError do
      @pdf.set_image(:signature, 'nonexistent.png')
    end
    assert_match 'is not found', err.message
  end

  def test_set_image_base64_with_invalid_data
    invalid_base64 = 'invalid_base64_data'
    err = assert_raises ArgumentError do
      @pdf.set_image_base64(:photo, invalid_base64)
    end
    assert_match 'Invalid base64', err.message
  end

  def test_set_multiple_images
    assert @pdf.set_image(:signature, 'test/files/signature.png')
    assert @pdf.set_image_base64(:photo, @base64)
  end

  def test_set_image_overwrites_previous_image
    @pdf.set_image(:signature, 'test/files/signature.png')

    assert @pdf.set_image(:signature, 'test/files/signature.png')
  end

  def test_set_image_base64_overwrites_previous_value
    @pdf.set_image_base64(:photo, @base64)

    assert @pdf.set_image_base64(:photo, @base64)
  end

  def test_set_image_with_string_key
    assert @pdf.set_image('signature', 'test/files/signature.png')
  end

  def test_set_image_base64_with_string_key
    assert @pdf.set_image_base64('photo', @base64)
  end
end
