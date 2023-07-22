enum UserContributionType {
  UNKNOWN,
  PRODUCT_EDITED,
  PRODUCT_ADDED_TO_SHOP,
  REPORT_WAS_MADE,
  SHOP_CREATED,
  LEGACY_PRODUCT_EDITED,
}

UserContributionType userContributionTypeFromCode(int code) {
  return UserContributionType.values.firstWhere(
      (element) => element.persistentCode == code,
      orElse: () => UserContributionType.UNKNOWN);
}

extension UserContributionTypeExt on UserContributionType {
  int get persistentCode {
    switch (this) {
      case UserContributionType.UNKNOWN:
        return -1;
      case UserContributionType.PRODUCT_EDITED:
        return 1;
      case UserContributionType.PRODUCT_ADDED_TO_SHOP:
        return 2;
      case UserContributionType.REPORT_WAS_MADE:
        return 3;
      case UserContributionType.SHOP_CREATED:
        return 4;
      case UserContributionType.LEGACY_PRODUCT_EDITED:
        return 5;
    }
  }
}
