/// Error parameters for the error messages and the parsing keys
class NetKitErrorParams {
  /// Constructor for the error parameters
  /// All parameters are optional and have default values
  const NetKitErrorParams({
    this.messageKey = 'message',
    this.statusCodeKey = 'status',
    this.noInternetError = 'No internet connection',
    this.couldNotParseError = 'Could not parse the error',
    this.jsonNullError = 'Empty error message',
    this.jsonIsEmptyError = 'Empty error message',
    this.notMapTypeError = 'Could not parse the response: Not a Map type',
    this.jsonUnsupportedObjectError = 'Unsupported object',
  });

  /// The key to use for error messages
  /// The default value is ['message']
  final String messageKey;

  /// The key to use for error status codes
  /// The default value is ['status']
  final String statusCodeKey;

  /// The error message for the no internet error
  /// The default value is ['No internet connection']
  final String noInternetError;

  /// The error message for the could not parse error
  /// The default value is ['Could not parse the error']
  final String couldNotParseError;

  /// The error message for the null JSON error
  /// The default value is ['Empty error message']
  final String jsonNullError;

  /// The error message for the empty JSON error
  /// The default value is ['Empty error message']
  final String jsonIsEmptyError;

  /// The error message for the not map type error
  /// The default value is ['Could not parse the response: Not a Map type']
  final String notMapTypeError;

  /// The error message for the unsupported object error
  /// The default value is ['Unsupported object']
  final String jsonUnsupportedObjectError;
}
