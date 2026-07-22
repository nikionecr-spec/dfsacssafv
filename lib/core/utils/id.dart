import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Generates a random, collision-resistant identifier for new entities.
String newId() => _uuid.v4();
