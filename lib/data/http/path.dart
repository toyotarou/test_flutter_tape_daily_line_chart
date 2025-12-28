enum APIPath { getAllMoneySum }

extension APIPathExtension on APIPath {
  String? get value {
    switch (this) {
      case APIPath.getAllMoneySum:
        return 'getAllMoneySum';
    }
  }
}
