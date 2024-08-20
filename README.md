# NetKit

NetKit is a Dart package designed to handle HTTP requests and responses efficiently. It
extends `DioMixin` providing a structured and consistent way to perform network operations.

## Features
- Supports various HTTP methods (GET, POST, PUT, DELETE, PACTH)
- Configurable base URLs for development and production
- Logging of network requests and responses
- Error handling and response validation
- Parsing responses into models or lists of models or void

## Getting started

### Prerequisites

- Dart SDK
- Flutter SDK (if using with Flutter)

### Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  net_kit ^1.0.0
```

Then run:

```bash
$ flutter pub get
```

## Usage
### Initialization
Initialize the NetKitManager with the parameters:

```dart
final netKitManager = NetKitManager(
      baseUrl: 'https://api.behzod.dev',
      devBaseUrl: 'https://api-dev.behzod.dev',
      loggerEnabled: true,
      testMode: true,
      errorStatusCodeKey: 'status',
      errorMessageKey: 'description',
    );
```
### Sending requests

#### Requesting a List of Models

```dart
final response = await netKitManager.requestList(
  path: '/books',
  method: RequestMethod.get,
  model: BookModel(),
);

response.fold(
  (error) => print('Error: ${error.description}'),
  (books) => print('Books: $books'),
);
```

#### Requesting a Single Model

```dart
final response = await netKitManager.requestModel<BookModel>(
  path: '/book/1',
  method: RequestMethod.get,
  model: BookModel(),
);

response.fold(
  (error) => print('Error: ${error.description}'),
  (book) => print('Book: $book'),
);
```

#### Sending a Void Request
```dart
final response = await netKitManager.requestVoid(
  path: '/book/1',
  method: RequestMethod.DELETE,
);

response.fold(
  (error) => print('Error: ${error.description}'),
  (_) => print('Book deleted successfully'),
);
```

## Contributing
Contributions are welcome! Please open an issue or submit a pull request.  
## License
This project is licensed under the MIT License.
  
