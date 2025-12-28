import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'money_sum/money_sum.dart';

mixin ControllersMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  //==========================================//

  MoneySumState get moneySumState => ref.watch(moneySumProvider);

  MoneySum get moneySumNotifier => ref.read(moneySumProvider.notifier);

  //==========================================//
}
