import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/colors.dart';
import '../../db/conversation_dao.dart';
import '../../models/conversation.dart';
import '../../security/duress_manager.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';
import '../../widgets/conversation_tile.dart';
import '../../widgets/ds_button.dart';
import '../../widgets/ds_text_field.dart';
import '../../widgets/ds_bottom_sheet.dart';
import '../../security/app_lock_manager.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ConversationDao _dao = ConversationDao();
  List<Conversation> _conversations = [];
  List<Conversation> _filtered = [];
  bool _loading = true;
  bool _searchActive = false;
  bool _showArchived = false;
  final _searchController = TextEditingController();
  StreamSubscription? _chatsSub;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _loadLocal();
    _listenFirestore();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    _chatsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocal() async {
    final convs = await _dao.getAll();
    if (!mounted) return;
    setState(() {
      _conversations = convs;
      _filtered = _visibleConversations(convs);
      _loading = convs.isEmpty;
    });
  }

  void _listenFirestore() {
    final uid = _myUid;
    if (uid == null) return;
    _chatsSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen((snap) async {
      final convs = <Conversation>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final local = await _dao.getById(doc.id);
        final conv = Conversation(
          id: doc.id,
          partnerUid: (data['participants'] as List)
              .firstWhere((p) => p != uid, orElse: () => ''),
          partnerName: local?.partnerName ?? '',
          lastMessage: data['lastMessage'] as String? ?? '',
          lastMessageTs: data['lastMessageTs'] as int? ?? 0,
          muted: data['muted_$uid'] as bool? ?? false,
          archived: local?.archived ?? false,
        );
        convs.add(conv);
        await _dao.insert(conv);
      }
      convs.sort((a, b) => b.lastMessageTs.compareTo(a.lastMessageTs));
      if (!mounted) return;
      setState(() {
        _conversations = convs;
        _filtered = _visibleConversations(convs);
        _loading = false;
      });
    });
  }

  List<Conversation> _visibleConversations(List<Conversation> all) {
    return all.where((c) => _showArchived ? c.archived : !c.archived).toList();
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _visibleConversations(_conversations)
          .where((c) => c.partnerName.toLowerCase().contains(q))
          .toList();
    });
  }

  void _toggleSearch() => setState(() {
        _searchActive = true;
      });

  void _closeSearch() {
    setState(() {
      _searchActive = false;
      _searchController.clear();
      _filtered = _visibleConversations(_conversations);
    });
  }

  void _toggleArchive() {
    setState(() {
      _showArchived = !_showArchived;
      _filtered = _visibleConversations(_conversations);
    });
  }

  int get _archivedCount => _conversations.where((c) => c.archived).length;

  void _showPopupMenu() async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          button.size.width - 200, 56, 0, 0),
      color: colorSurface,
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem(value: 'new_chat', child: Text('New Chat', style: TextStyle(color: colorTextPrimary))),
        const PopupMenuItem(value: 'new_group', child: Text('New Group', style: TextStyle(color: colorTextPrimary))),
        const PopupMenuItem(value: 'settings', child: Text('Settings', style: TextStyle(color: colorTextPrimary))),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'wipe', child: Text('Wipe & Exit', style: TextStyle(color: colorError))),
      ],
    ).then((value) {
      if (value == 'new_chat') context.push('/add-contact');
      else if (value == 'new_group') context.push('/create-group');
      else if (value == 'settings') context.push('/settings');
      else if (value == 'wipe') _confirmWipeAndExit();
    });
  }

  void _confirmWipeAndExit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorSurface,
        title: const Text('Wipe & Exit', style: TextStyle(color: colorTextPrimary)),
        content: const Text(
            'This will erase all local data and sign out. This cannot be undone.',
            style: TextStyle(color: colorTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: colorTextSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DuressManager.performWipe();
              if (!mounted) return;
              context.go('/sign-in');
            },
            child: const Text('Wipe', style: TextStyle(color: colorError)),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(Conversation conv) {
    DSBottomSheet.show(context, children: [
      ListTile(
        leading: Icon(conv.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            color: colorTextPrimary),
        title: Text(conv.archived ? 'Unarchive' : 'Archive',
            style: const TextStyle(color: colorTextPrimary)),
        onTap: () async {
          Navigator.pop(context);
          await _dao.update(conv.id, {'archived': conv.archived ? 0 : 1});
          _loadLocal();
        },
      ),
      ListTile(
        leading: Icon(conv.muted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            color: colorTextPrimary),
        title: Text(conv.muted ? 'Unmute' : 'Mute',
            style: const TextStyle(color: colorTextPrimary)),
        onTap: () async {
          Navigator.pop(context);
          await _dao.update(conv.id, {'muted': conv.muted ? 0 : 1});
          _loadLocal();
        },
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: colorError),
        title: const Text('Delete', style: TextStyle(color: colorError)),
        onTap: () async {
          Navigator.pop(context);
          await _dao.delete(conv.id);
          _loadLocal();
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-contact'),
        backgroundColor: colorAccent,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: colorSurface,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (!_searchActive)
                    const Text('DuoShield',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTextPrimary))
                  else
                    Expanded(
                      child: DSTextField(
                        hint: 'Search...',
                        controller: _searchController,
                      ),
                    ),
                  if (!_searchActive) const Spacer(),
                  if (!_searchActive)
                    IconButton(
                      icon: const Icon(Icons.search, color: colorIconDefault),
                      onPressed: _toggleSearch,
                    ),
                  if (_searchActive)
                    IconButton(
                      icon: const Icon(Icons.close, color: colorIconDefault),
                      onPressed: _closeSearch,
                    ),
                  if (!_searchActive)
                    IconButton(
                      icon: const Icon(Icons.call_outlined, color: colorIconDefault),
                      onPressed: () => context.push('/call-history'),
                    ),
                  if (!_searchActive)
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: colorIconDefault),
                      onPressed: _showPopupMenu,
                    ),
                ],
              ),
            ),
            if (_archivedCount > 0 && !_showArchived)
              GestureDetector(
                onTap: _toggleArchive,
                child: Container(
                  color: colorSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.archive_outlined, color: colorTextSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text('Archived ($_archivedCount)',
                          style: const TextStyle(color: colorTextSecondary, fontSize: 13)),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: colorTextMuted),
                    ],
                  ),
                ),
              ),
            if (_showArchived)
              GestureDetector(
                onTap: _toggleArchive,
                child: Container(
                  color: colorSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: colorTextSecondary, size: 18),
                      SizedBox(width: 8),
                      Text('Back to Chats', style: TextStyle(color: colorTextSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            if (_loading)
              Expanded(child: _buildShimmer())
            else if (_filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 64, color: colorTextMuted),
                      const SizedBox(height: 16),
                      const Text('No conversations yet',
                          style: TextStyle(color: colorTextSecondary, fontSize: 16)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 160,
                        child: DSButton(
                          text: 'Add a Contact',
                          gradient: true,
                          onTap: () => context.push('/add-contact'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => ConversationTile(
                    conversation: _filtered[i],
                    onTap: () => context.push(
                        '/chat/${_filtered[i].id}',
                        extra: {'partnerUid': _filtered[i].partnerUid}),
                    onLongPress: () => _showConversationOptions(_filtered[i]),
                    onArchive: () async {
                      await _dao.update(_filtered[i].id, {'archived': 1});
                      _loadLocal();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: colorSurface,
      highlightColor: colorSurfaceVariant,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => ListTile(
          leading: const CircleAvatar(radius: 26, backgroundColor: Colors.white),
          title: Container(height: 14, color: Colors.white),
          subtitle: Container(height: 12, color: Colors.white),
        ),
      ),
    );
  }
}
