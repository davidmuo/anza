import 'package:flutter/material.dart';

import '../models/user.dart';
import 'mini_avatar.dart';

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double radius;

  const UserAvatar({super.key, required this.user, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return MiniAvatar(
      seed: user.id,
      label: user.initials,
      color: user.avatarColor,
      radius: radius,
    );
  }
}