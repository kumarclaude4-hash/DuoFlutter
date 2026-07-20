import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/display_name_screen.dart';
import 'screens/auth/seed_phrase_display_screen.dart';
import 'screens/auth/restore_from_seed_screen.dart';
import 'screens/lock/lock_screen.dart';
import 'screens/conversations/conversation_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/group_chat/group_chat_screen.dart';
import 'screens/create_group/create_group_screen.dart';
import 'screens/add_contact/add_contact_screen.dart';
import 'screens/contact_detail/contact_detail_screen.dart';
import 'screens/call/call_screen.dart';
import 'screens/call/call_history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/pin_settings_screen.dart';
import 'screens/settings/duress_pin_screen.dart';
import 'screens/settings/profile_settings_screen.dart';
import 'screens/settings/backup_settings_screen.dart';
import 'screens/settings/privacy_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/safety_numbers/safety_numbers_screen.dart';
import 'screens/media_viewer/media_viewer_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/display-name',
      builder: (context, state) => const DisplayNameScreen(),
    ),
    GoRoute(
      path: '/seed-phrase-display',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return SeedPhraseDisplayScreen(
          mnemonic: extra['mnemonic'] as String,
          displayName: extra['displayName'] as String,
          identityKey: extra['identityKey'] as String,
          userId: extra['userId'] as String,
        );
      },
    ),
    GoRoute(
      path: '/restore-from-seed',
      builder: (context, state) => const RestoreFromSeedScreen(),
    ),
    GoRoute(
      path: '/lock',
      builder: (context, state) => const LockScreen(),
    ),
    GoRoute(
      path: '/conversations',
      builder: (context, state) => const ConversationListScreen(),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ChatScreen(
          conversationId: conversationId,
          partnerUid: extra['partnerUid'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/group-chat/:groupId',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        return GroupChatScreen(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/create-group',
      builder: (context, state) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: '/add-contact',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return AddContactScreen(prefill: extra['prefill'] as String?);
      },
    ),
    GoRoute(
      path: '/contact-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ContactDetailScreen(
          partnerUid: extra['partnerUid'] as String,
          partnerName: extra['partnerName'] as String,
          conversationId: extra['conversationId'] as String,
        );
      },
    ),
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CallScreen(
          partnerUid: extra['partnerUid'] as String,
          partnerName: extra['partnerName'] as String,
          isVideo: extra['isVideo'] as bool? ?? false,
          incomingCallId: extra['incomingCallId'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/call-history',
      builder: (context, state) => const CallHistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/pin',
      builder: (context, state) => const PinSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/duress-pin',
      builder: (context, state) => const DuressPinScreen(),
    ),
    GoRoute(
      path: '/settings/profile',
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/backup',
      builder: (context, state) => const BackupSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/safety-numbers',
      builder: (context, state) {
        final partnerUid = (state.extra as String?) ?? '';
        return SafetyNumbersScreen(partnerUid: partnerUid);
      },
    ),
    GoRoute(
      path: '/media-viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return MediaViewerScreen(
          localPath: extra['localPath'] as String?,
          networkUrl: extra['networkUrl'] as String?,
          mediaType: extra['mediaType'] as String?,
          heroTag: extra['heroTag'] as String?,
        );
      },
    ),
  ],
);
