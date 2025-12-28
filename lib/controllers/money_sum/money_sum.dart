import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/http/client.dart';
import '../../data/http/path.dart';
import '../../extensions/extensions.dart';
import '../../model/money_sum_model.dart';
import '../../utility/utility.dart';

part 'money_sum.freezed.dart';

part 'money_sum.g.dart';

@freezed
class MoneySumState with _$MoneySumState {
  const factory MoneySumState({
    @Default(<MoneySumModel>[]) List<MoneySumModel> moneySumList,
    @Default(<String, MoneySumModel>{}) Map<String, MoneySumModel> moneySumMap,
  }) = _MoneySumState;
}

@riverpod
class MoneySum extends _$MoneySum {
  final Utility utility = Utility();

  ///
  @override
  MoneySumState build() => const MoneySumState();

  //============================================== api

  ///
  Future<MoneySumState> fetchAllMoneySumData() async {
    final HttpClient client = ref.read(httpClientProvider);

    try {
      final List<MoneySumModel> list = <MoneySumModel>[];
      final Map<String, MoneySumModel> map = <String, MoneySumModel>{};

      // ignore: always_specify_types
      await client.post(path: APIPath.getAllMoneySum).then((value) {
        // ignore: avoid_dynamic_calls
        for (int i = 0; i < value['data'].length.toString().toInt(); i++) {
          // ignore: avoid_dynamic_calls
          final MoneySumModel val = MoneySumModel.fromJson(value['data'][i] as Map<String, dynamic>);

          list.add(val);

          map[val.date] = val;
        }
      });

      return state.copyWith(moneySumList: list, moneySumMap: map);
    } catch (e) {
      utility.showError('予期せぬエラーが発生しました');
      rethrow; // これにより呼び出し元でキャッチできる
    }
  }

  ///
  Future<void> getAllMoneySumData() async {
    try {
      final MoneySumState newState = await fetchAllMoneySumData();

      state = newState;
    } catch (_) {}
  }

  //============================================== api
}
