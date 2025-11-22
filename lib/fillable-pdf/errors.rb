class FillablePDF
  # Base error class for all FillablePDF errors
  class Error < StandardError; end

  # Raised when a field is not found in the PDF form
  class FieldNotFoundError < Error; end

  # Raised when invalid arguments are provided to a method
  class InvalidArgumentError < Error; end

  # Raised when a PDF file operation fails
  class FileOperationError < Error; end
end
