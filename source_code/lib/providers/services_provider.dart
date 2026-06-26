import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/task_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final taskServiceProvider = Provider<TaskService>((ref) => TaskService());
