import 'package:flutter/material.dart';

import '../data/seed_data.dart';
import '../models/community.dart';
import '../services/storage_service.dart';

/// Owns the community directory, the current user's joined-community set,
/// and the communities search query.
///
/// Membership is "join/leave" only (no approval flow), persisted as a flat
/// list of community ids — the same shape as [EventsProvider]'s RSVP ids.
/// User-created communities go through the same approval flow as events
/// (see [CommunityStatus]) and are kept in-memory alongside the seed list.
class CommunitiesProvider extends ChangeNotifier {
  final StorageService _storage;

  List<Community> _communities = List.of(SeedData.communities);
  Set<String> _joinedIds = {};
  String _searchQuery = '';

  CommunitiesProvider(this._storage) {
    _joinedIds = _storage.loadJoinedCommunityIds().toSet();
  }

  String get searchQuery => _searchQuery;

  bool isJoined(String communityId) => _joinedIds.contains(communityId);

  /// Approved communities matching the search query (by name or description).
  List<Community> get communities {
    final query = _searchQuery.trim().toLowerCase();
    final approved = _communities.where((c) => c.status == CommunityStatus.approved);
    if (query.isEmpty) return List.unmodifiable(approved);
    return approved
        .where((c) =>
            c.name.toLowerCase().contains(query) || c.description.toLowerCase().contains(query))
        .toList();
  }

  /// Communities the current user has joined, plus any communities they've
  /// created that are still pending approval (so they can track status).
  List<Community> myCommunities(String userId) => _communities
      .where((c) => _joinedIds.contains(c.id) || c.posterId == userId)
      .toList();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Effective member count — bumps the seeded count by one while the
  /// current user is a member, so joining/leaving visibly changes the tile.
  int memberCountFor(Community community) {
    return community.memberCount + (_joinedIds.contains(community.id) ? 1 : 0);
  }

  /// Adds a user-created community and auto-joins its creator, regardless
  /// of approval status, so they can track it on their "My communities" tab.
  Future<void> addCommunity(Community community) async {
    _communities = [..._communities, community];
    _joinedIds = {..._joinedIds, community.id};
    notifyListeners();
    await _storage.saveJoinedCommunityIds(_joinedIds.toList());
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
