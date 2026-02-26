import 'dart:async';
import 'package:bmp_login/domain/entity/loan_request.dart';
import 'package:bmp_login/feature/authentication/loan/data/loan_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PaginationController<T> {
  int get initialPage;
  int get pageSize;

  late int currentPage = initialPage;

  FutureOr<List<T>> loadPage(
    int page, {
    required int size,
    String? keyword,
  });

  Future<void> loadNextPage({String? keyword});

  int nextPage(int currentPage);
}

mixin AsyncPaginationController<T> on AsyncNotifier<List<T>>
    implements PaginationController<T> {
  @override
  late int currentPage = initialPage;

  @override
  FutureOr<List<T>> build() async {
    return loadPage(
      initialPage,
      size: pageSize,
    );
  }

  @override
  Future<void> loadNextPage({String? keyword}) async {
    final previousState = state;

    state = const AsyncLoading();

    final newState = await AsyncValue.guard<List<T>>(() async {
      currentPage = nextPage(currentPage);

      final elements = await loadPage(
        currentPage,
        size: pageSize,
        keyword: keyword,
      );

      return [...?previousState.valueOrNull, ...elements];
    });

    state = newState;
  }
}

class LoanRequestPaginationController extends AsyncNotifier<List<LoanRequest>>
    with AsyncPaginationController<LoanRequest> {
  final LoanService _loanService;

  LoanRequestPaginationController(this._loanService);

  @override
  int get initialPage => 1;

  @override
  int get pageSize => 20;

  @override
  FutureOr<List<LoanRequest>> loadPage(
    int page, {
    required int size,
    String? keyword,
  }) async {
    return _loanService.paginationFilter(
      page: page,
      size: size,
      keyword: keyword ?? '',
    );
  }

  @override
  int nextPage(int currentPage) => currentPage + 1;
}

final loanRequestPaginationControllerProvider =
    AsyncNotifierProvider<LoanRequestPaginationController, List<LoanRequest>>(
  () => LoanRequestPaginationController(LoanService()),
);
