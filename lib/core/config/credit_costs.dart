import 'package:easy_localization/easy_localization.dart';

/// Shared credit pricing used across UI copy and feature flows.
abstract class CreditCosts {
  CreditCosts._();

  static const int profileAnalysis = 1;
  static const int chatAnalysis = 1;
  static const int photoEnhancement = 3;

  static String actionCardLabel(int amount) {
    final key = amount == 1
        ? 'enhance.credit_cost'
        : 'enhance.credit_cost_plural';
    return key.tr(args: [amount.toString()]);
  }

  static String usageLabel(int amount) {
    final key = amount == 1
        ? 'enhance.cost_label'
        : 'enhance.cost_label_plural';
    return key.tr(args: [amount.toString()]);
  }
}
