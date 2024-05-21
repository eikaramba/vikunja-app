import 'dart:ui';

import 'package:intl/intl.dart';

datetimeToUnixTimestamp(DateTime dt) {
  return (dt.millisecondsSinceEpoch / 1000).round();
}

dateTimeFromUnixTimestamp(int timestamp) {
  return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

DateFormat getDateFormat(Locale locale) {
  switch (locale.languageCode) {
    case 'de':
      return DateFormat('dd.MM.yy HH:mm');
    case 'en':
      return DateFormat('MM/dd/yy h:mm a');
    default:
      return DateFormat.yMd(locale.languageCode).add_jm();
  }
}
