import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';

sealed class Result<T, E> {
  const Result();
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}

// extension DropNullExtension<T> on Stream<T?> {
//   Stream<T> dropNull() => where((value) => value != null).cast<T>();

//   Stream<Result<T?, Object>> unfailable() {
//     return map<Result<T?, Object>>(
//       (value) => Success(value),
//     ).onErrorReturnWith((error, stackTrace) => Failure(error));
//   }
// }
