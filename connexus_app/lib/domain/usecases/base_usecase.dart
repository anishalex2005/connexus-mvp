import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case without parameters
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// Base class for use case parameters
abstract class Params extends Equatable {
  const Params();
}

/// Empty parameters for use cases that don't need params
class NoParams extends Params {
  @override
  List<Object?> get props => [];
}



