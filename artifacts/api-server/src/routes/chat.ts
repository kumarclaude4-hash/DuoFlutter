import { Router } from "express";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getFirebaseApp } from "../lib/firebase.js";
import { requireAuth, type AuthedRequest } from "../middlewares/requireAuth.js";

const router = Router();

/**
 * POST /api/createChat
 */
router.post("/createChat", requireAuth, async (req: AuthedRequest, res) => {
  const { myUid, partnerUid } = req.body as {
    myUid?: string;
    partnerUid?: string;
  };

  if (!myUid || !partnerUid) {
    res.status(400).json({ error: "myUid and partnerUid are required" });
    return;
  }

  if (req.user!.uid !== myUid) {
    res.status(403).json({ error: "myUid must match authenticated user" });
    return;
  }

  const sorted = [myUid, partnerUid].sort();
  const chatId = `${sorted[0]}_${sorted[1]}`;

  try {
    const db = getFirestore(getFirebaseApp());
    const chatRef = db.collection("chats").doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        participants: sorted,
        createdAt: FieldValue.serverTimestamp(),
        lastMessage: "",
        lastMessageTs: 0,
      });
      console.log("[createChat] Created chat:", chatId);
    }

    res.json({ chatId });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[createChat] Error:", message);
    res.status(500).json({ error: "createChat failed" });
  }
});

/**
 * POST /api/migrateUid
 */
router.post("/migrateUid", requireAuth, async (req: AuthedRequest, res) => {
  const { oldUid, newUid } = req.body as {
    oldUid?: string;
    newUid?: string;
  };

  if (!oldUid || !newUid) {
    res.status(400).json({ error: "oldUid and newUid are required" });
    return;
  }

  if (req.user!.uid !== newUid) {
    res.status(403).json({ error: "newUid must match authenticated user" });
    return;
  }

  try {
    const db = getFirestore(getFirebaseApp());
    const batch = db.batch();

    const oldRef = db.collection("identities").doc(oldUid);
    const newRef = db.collection("identities").doc(newUid);
    const oldDoc = await oldRef.get();

    if (oldDoc.exists) {
      batch.set(newRef, { ...oldDoc.data(), uid: newUid });
      batch.delete(oldRef);
    }

    await batch.commit();
    console.log("[migrateUid]", oldUid, "->", newUid);
    res.json({ success: true });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[migrateUid] Error:", message);
    res.status(500).json({ error: "migrateUid failed" });
  }
});

/**
 * POST /api/removeGroupMember
 */
router.post(
  "/removeGroupMember",
  requireAuth,
  async (req: AuthedRequest, res) => {
    const { groupId, memberUid } = req.body as {
      groupId?: string;
      memberUid?: string;
    };

    if (!groupId || !memberUid) {
      res.status(400).json({ error: "groupId and memberUid are required" });
      return;
    }

    try {
      const db = getFirestore(getFirebaseApp());
      const groupRef = db.collection("groups").doc(groupId);
      const groupDoc = await groupRef.get();

      if (!groupDoc.exists) {
        res.status(404).json({ error: "Group not found" });
        return;
      }

      const groupData = groupDoc.data()!;

      if (groupData["createdBy"] !== req.user!.uid) {
        res
          .status(403)
          .json({ error: "Only the group creator can remove members" });
        return;
      }

      if (memberUid === groupData["createdBy"]) {
        res.status(400).json({ error: "Cannot remove group creator" });
        return;
      }

      await groupRef.update({
        members: FieldValue.arrayRemove(memberUid),
      });

      await db
        .collection("groups")
        .doc(groupId)
        .collection("members")
        .doc(memberUid)
        .delete();

      console.log("[removeGroupMember] Removed", memberUid, "from", groupId);
      res.json({ success: true });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      console.error("[removeGroupMember] Error:", message);
      res.status(500).json({ error: "removeGroupMember failed" });
    }
  }
);

export default router;
