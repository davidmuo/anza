import 'package:flutter/material.dart';

import '../models/user.dart';

/// Circular initials avatar colored with the user's [AppUser.avatarColor].
/// Used in the profile header, chat bubbles' sender context, and lists —
/// avoids needing real profile photos, which would break offline-only.
class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double radius;

  const UserAvatar({super.key, required this.user, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: user.avatarColor,
      child: Text(
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
