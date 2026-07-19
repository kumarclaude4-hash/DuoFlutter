const express = require('express');
const admin = require('../firebase');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /createChat
 * Body: { myUid: string, partnerUid: string }
 * Response: { chatId: string }
 *
 * Creates a deterministic chatId from the two UIDs (sorted, joined with "_")
 * and writes the conversation document to Firestore if it doesn't exist.
 */
router.post('/createChat', requireAuth, async (req, res) => {
  const { myUid, partnerUid } = req.body;

  if (!myUid || !partnerUid) {
    return res.status(400).json({ error: 'myUid and partnerUid are required' });
  }

  // Ensure the authenticated user is one of the participants
  if (req.user.uid !== myUid) {
    return res.status(403).json({ error: 'myUid must match authenticated user' });
  }

  // Deterministic chatId: sort UIDs alphabetically so both sides get the same ID
  const sorted = [myUid, partnerUid].sort();
  const chatId = `${sorted[0]}_${sorted[1]}`;

  try {
    const db = admin.firestore();
    const chatRef = db.collection('chats').doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        participants: sorted,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: '',
        lastMessageTs: 0,
      });
      console.log('[createChat] Created chat:', chatId);
    }

    return res.json({ chatId });
  } catch (err) {
    console.error('[createChat] Error:', err.message);
    return res.status(500).json({ error: 'createChat failed' });
  }
});

/**
 * POST /migrateUid
 * Body: { oldUid: string, newUid: string }
 * Response: { success: true }
 *
 * Reassigns Firestore data from oldUid to newUid.
 * Used when a user restores from seed phrase and gets the same UID.
 */
router.post('/migrateUid', requireAuth, async (req, res) => {
  const { oldUid, newUid } = req.body;

  if (!oldUid || !newUid) {
    return res.status(400).json({ error: 'oldUid and newUid are required' });
  }

  if (req.user.uid !== newUid) {
    return res.status(403).json({ error: 'newUid must match authenticated user' });
  }

  try {
    const db = admin.firestore();
    const batch = db.batch();

    // Update identity document
    const oldIdentityRef = db.collection('identities').doc(oldUid);
    const newIdentityRef = db.collection('identities').doc(newUid);
    const oldIdentityDoc = await oldIdentityRef.get();

    if (oldIdentityDoc.exists) {
      batch.set(newIdentityRef, { ...oldIdentityDoc.data(), uid: newUid });
      batch.delete(oldIdentityRef);
    }

    await batch.commit();
    console.log('[migrateUid]', oldUid, '->', newUid);
    return res.json({ success: true });
  } catch (err) {
    console.error('[migrateUid] Error:', err.message);
    return res.status(500).json({ error: 'migrateUid failed' });
  }
});

/**
 * POST /removeGroupMember
 * Body: { groupId: string, memberUid: string }
 * Response: { success: true }
 *
 * Removes a member from a Firestore group document.
 * Only group admins (validated server-side) may call this.
 */
router.post('/removeGroupMember', requireAuth, async (req, res) => {
  const { groupId, memberUid } = req.body;

  if (!groupId || !memberUid) {
    return res.status(400).json({ error: 'groupId and memberUid are required' });
  }

  try {
    const db = admin.firestore();
    const groupRef = db.collection('groups').doc(groupId);
    const groupDoc = await groupRef.get();

    if (!groupDoc.exists) {
      return res.status(404).json({ error: 'Group not found' });
    }

    const groupData = groupDoc.data();

    // Only the group creator can remove members
    if (groupData.createdBy !== req.user.uid) {
      return res.status(403).json({ error: 'Only the group creator can remove members' });
    }

    // Cannot remove the creator themselves
    if (memberUid === groupData.createdBy) {
      return res.status(400).json({ error: 'Cannot remove group creator' });
    }

    // Remove member from members array
    await groupRef.update({
      members: admin.firestore.FieldValue.arrayRemove(memberUid),
    });

    // Remove member's group_members document
    const memberRef = db.collection('groups').doc(groupId)
      .collection('members').doc(memberUid);
    await memberRef.delete();

    console.log('[removeGroupMember] Removed', memberUid, 'from', groupId);
    return res.json({ success: true });
  } catch (err) {
    console.error('[removeGroupMember] Error:', err.message);
    return res.status(500).json({ error: 'removeGroupMember failed' });
  }
});

module.exports = router;
