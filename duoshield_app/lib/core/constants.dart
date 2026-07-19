class AppConstants {
<<<<<<< HEAD
<<<<<<< HEAD
  static const String pushServerUrl = 'https://duoshield.onrender.com';
=======
  // Push server URL — points to the Replit API server (/api prefix routes duoshield endpoints)
  static const String pushServerUrl = 'https://b96d839a-c5c1-4a6f-a779-cd9c54b5b562-00-2hpchaypc9i5j.pike.replit.dev/api';
>>>>>>> f87dab5 (Add request validation middleware to API server routes)
=======
  static const String pushServerUrl = 'https://duoshield-server.onrender.com';
>>>>>>> 39f58b2 (Update constants and add replit documentation)

  static const String firestoreUsers = 'users';
  static const String firestoreIdentities = 'identities';
  static const String firestoreChats = 'chats';
  static const String firestoreGroups = 'groups';
  static const String firestoreCalls = 'calls';

  static const String prefAppPinHash = 'app_pin_hash_';
  static const String prefDuressPinHash = 'duress_pin_hash_';
  static const String prefSignalPreKeyNextId = 'signal_prekey_next_id';
  static const String prefSignalSignedPreKeyCurrent = 'signal_signed_prekey_current';
  static const String prefSignalSignedPreKeyPrev = 'signal_signed_prekey_prev';
  static const String prefTurnUsername = 'turn_username';
  static const String prefTurnCredential = 'turn_credential';
  static const String prefTurnFetchedAt = 'turn_fetched_at';
  static const String prefBackgroundTs = 'background_ts';
  static const String prefSignedOutReasonInactivity = 'signed_out_reason_inactivity';
  static const String prefDuressWipeInProgress = 'duress_wipe_in_progress';
  static const String prefSafetyNumChanged = 'safety_num_changed_';
  static const String prefSafetyNumVerified = 'safety_num_verified_';
  static const String prefSafetyNumKey = 'safety_num_key_';
  static const String prefIsPaired = 'is_paired';
  static const String prefConversationId = 'conversation_id';
  static const String prefPartnerUid = 'partner_uid';
  static const String prefSpkRotatedAt = 'spk_rotated_at';
  static const String prefLastBackupDate = 'last_backup_date';
  static const String prefBiometricEnabled = 'biometric_enabled';

  static const String prefReadReceiptsEnabled = 'read_receipts_enabled';
  static const String prefShowLastSeen = 'show_last_seen';
  static const String prefTypingIndicators = 'typing_indicators';
  static const String prefLinkPreviews = 'link_previews';
  static const String prefNotifMessageSounds = 'notif_message_sounds';
  static const String prefNotifCallSounds = 'notif_call_sounds';
  static const String prefNotifGroupSounds = 'notif_group_sounds';
  static const String prefNotifShowPreview = 'notif_show_preview';

  static const int lockDelayMs = 30 * 1000;
  static const int autoSignOutMs = 15 * 60 * 1000;
  static const int turnRefreshMs = 23 * 3600 * 1000;
  static const int preKeyThreshold = 10;
  static const int preKeyBatchSize = 25;
  static const int spkRotationDays = 7;
}
