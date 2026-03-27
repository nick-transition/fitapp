// Conditional export: web implementation on web, stub everywhere else.
export 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils_web.dart';
