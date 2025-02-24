import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthorizationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define permission levels for different roles
  static const Map<String, int> _roleHierarchy = {
    'SuperAdmin': 100,
    'Admin': 80,
    'Manager': 60,
    'Supervisor': 40,
    'User': 20,
    'Guest': 10,
  };

  // Define permissions for different features
  static const Map<String, Map<String, int>> _featurePermissions = {
    'assets': {
      'create': 40,  // Supervisor and above
      'read': 20,    // User and above
      'update': 40,  // Supervisor and above
      'delete': 80,  // Admin and above
    },
    'users': {
      'create': 80,  // Admin and above
      'read': 60,    // Manager and above
      'update': 80,  // Admin and above
      'delete': 100, // SuperAdmin only
    },
    'reports': {
      'generate': 40,  // Supervisor and above
      'view': 20,      // User and above
      'export': 60,    // Manager and above
    },
    'maintenance': {
      'schedule': 40,  // Supervisor and above
      'approve': 60,   // Manager and above
      'complete': 40,  // Supervisor and above
    },
    'settings': {
      'view': 20,      // User and above
      'modify': 80,    // Admin and above
    },
  };

  // Cache user role to minimize Firestore reads
  String? _cachedRole;
  DateTime? _roleLastChecked;
  static const Duration _roleCacheDuration = Duration(minutes: 5);

  // Get current user's role
  Future<String> getCurrentUserRole() async {
    // Check if we have a valid cached role
    if (_cachedRole != null && _roleLastChecked != null) {
      final cacheDiff = DateTime.now().difference(_roleLastChecked!);
      if (cacheDiff < _roleCacheDuration) {
        return _cachedRole!;
      }
    }

    final user = _auth.currentUser;
    if (user == null) return 'Guest';

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] as String? ?? 'Guest';
      
      // Update cache
      _cachedRole = role;
      _roleLastChecked = DateTime.now();
      
      return role;
    } catch (e) {
      print('Error getting user role: $e');
      return 'Guest';
    }
  }

  // Check if user has permission for a specific action
  Future<bool> hasPermission(String feature, String action) async {
    final userRole = await getCurrentUserRole();
    final userLevel = _roleHierarchy[userRole] ?? 0;
    
    final requiredLevel = _featurePermissions[feature]?[action] ?? 100;
    return userLevel >= requiredLevel;
  }

  // Check multiple permissions at once
  Future<Map<String, bool>> checkMultiplePermissions(
    List<Map<String, String>> permissions,
  ) async {
    final userRole = await getCurrentUserRole();
    final userLevel = _roleHierarchy[userRole] ?? 0;
    
    return Map.fromEntries(
      permissions.map((permission) {
        final feature = permission['feature']!;
        final action = permission['action']!;
        final requiredLevel = _featurePermissions[feature]?[action] ?? 100;
        return MapEntry('$feature.$action', userLevel >= requiredLevel);
      }),
    );
  }

  // Get all permissions for current user
  Future<Map<String, Map<String, bool>>> getAllPermissions() async {
    final userRole = await getCurrentUserRole();
    final userLevel = _roleHierarchy[userRole] ?? 0;
    
    return Map.fromEntries(
      _featurePermissions.entries.map((feature) {
        return MapEntry(
          feature.key,
          Map.fromEntries(
            feature.value.entries.map((action) {
              return MapEntry(
                action.key,
                userLevel >= action.value,
              );
            }),
          ),
        );
      }),
    );
  }

  // Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    // Verify that the new role is valid
    if (!_roleHierarchy.containsKey(newRole)) {
      throw ArgumentError('Invalid role: $newRole');
    }

    // Check if current user has permission to update roles
    final currentUserRole = await getCurrentUserRole();
    final currentUserLevel = _roleHierarchy[currentUserRole] ?? 0;
    final newRoleLevel = _roleHierarchy[newRole] ?? 0;

    // User can only assign roles lower than their own
    if (currentUserLevel <= newRoleLevel) {
      throw Exception('Insufficient permissions to assign this role');
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      // Clear role cache for the affected user
      if (userId == _auth.currentUser?.uid) {
        _cachedRole = null;
        _roleLastChecked = null;
      }
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Get available roles that current user can assign
  Future<List<String>> getAssignableRoles() async {
    final currentUserRole = await getCurrentUserRole();
    final currentUserLevel = _roleHierarchy[currentUserRole] ?? 0;

    return _roleHierarchy.entries
        .where((role) => role.value < currentUserLevel)
        .map((role) => role.key)
        .toList();
  }

  // Check if user can access a specific screen/route
  Future<bool> canAccessRoute(String routeName) async {
    final Map<String, int> routePermissions = {
      '/assets': 20,        // User and above
      '/users': 60,         // Manager and above
      '/reports': 40,       // Supervisor and above
      '/maintenance': 40,   // Supervisor and above
      '/settings': 20,      // User and above
      '/admin': 80,         // Admin and above
    };

    final userRole = await getCurrentUserRole();
    final userLevel = _roleHierarchy[userRole] ?? 0;
    final requiredLevel = routePermissions[routeName] ?? 100;

    return userLevel >= requiredLevel;
  }

  // Clear cached role
  void clearCache() {
    _cachedRole = null;
    _roleLastChecked = null;
  }
} 