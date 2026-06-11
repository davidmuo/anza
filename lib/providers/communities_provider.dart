import 'package:flutter/material.dart';

import '../data/seed_data.dart';
import '../models/community.dart';
import '../services/storage_service.dart';

/// Owns the community directory, the current user's joined-community set,
/// and the communities search query.
///
/// Membership is "join/leave" only (no approval flow), persisted as a flat
/// list of community ids — the same shape as [EventsProvider]'s RSVP ids.
class CommunitiesProvider extends ChangeNotifier {
  final StorageService _storage;

  final List<Community> _communities = SeedData.communities;
  Set<String> _joinedIds = {};
  String _searchQuery = '';

  CommunitiesProvider(this._storage) {
    _joinedIds = _storage.loadJoinedCommunityIds().toSet();
  }

  String get searchQuery => _searchQuery;

  bool isJoined(String communityId) => _joinedIds.contains(communityId);

  /// Communities matching the search query (by name or description).
  List<Community> get communities {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(_communities);
    return _communities
        .where((c) =>
            c.name.toLowerCase().contains(query) || c.description.toLowerCase().contains(query))
        .toList();
  }

  /// Communities the current user has joined.
  List<Community> get myCommunities =>
      _communities.where((c) => _joinedIds.contains(c.id)).toList();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Effective member count — bumps the seeded count by one while the
  /// current user is a member, so joining/leaving visibly changes the tile.
  int memberCountFor(Community community) {
    return community.memberCount + (_joinedIds.contains(community.id) ? 1 : 0);
  }

  Future<void> toggleJoin(String communityId) async {
    if (_joinedIds.contains(communityId)) {
      _joinedIds = {..._joinedIds}..remove(communityId);
    } else {
      _joinedIds = {..._joinedIds, communityId};
    }
    notifyListeners();
    await _storage.saveJoinedCommunityIds(_joinedIds.toList());
  }

  /// Simulated refresh for pull-to-refresh — there's no backend to poll, so
  /// this just gives the spinner something to wait on before redrawing.
  Future<void> refresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
    notifyListeners();
  }
}
