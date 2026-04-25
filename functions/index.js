// Cloud Functions for Resonance
// Handles match creation, push notifications, and account cleanup.

import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();

// MARK: - Match Creation (Callable)

/**
 * Creates a match between two users. Only callable by authenticated users.
 * Validates that the caller is one of the users, prevents duplicates,
 * and enforces userIds.length === 2.
 *
 * @param {Object} data
 * @param {string[]} data.userIds - Exactly two user IDs.
 * @param {string} data.matchType - "realtime", "historical", or "discovery".
 * @param {Object} [data.triggerSong] - { id, name, artistName }
 * @param {Object} [data.triggerArtist] - { id, name }
 * @param {number} [data.similarityScore] - 0.0–1.0 for historical matches.
 * @returns {{ matchId: string }} The ID of the created match document.
 */
export const createMatch = onCall(async (request) => {
  // 1. Auth check
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in to create a match.");
  }

  const callerUid = request.auth.uid;
  const { userIds, matchType, triggerSong, triggerArtist, similarityScore } = request.data;

  // 2. Rate limit: max 10 match creations per hour per user
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
  const recentMatches = await db
    .collection("matches")
    .where("userIds", "array-contains", callerUid)
    .where("createdAt", ">=", oneHourAgo)
    .count()
    .get();

  if (recentMatches.data().count >= 10) {
    throw new HttpsError("resource-exhausted", "Too many matches created. Try again later.");
  }

  // 3. Validate userIds
  if (!Array.isArray(userIds) || userIds.length !== 2) {
    throw new HttpsError("invalid-argument", "userIds must be an array of exactly 2 strings.");
  }
  if (!userIds.every((id) => typeof id === "string" && id.length > 0)) {
    throw new HttpsError("invalid-argument", "Each userId must be a non-empty string.");
  }
  if (!userIds.includes(callerUid)) {
    throw new HttpsError("permission-denied", "Caller must be one of the matched users.");
  }

  // 3. Validate matchType
  const validTypes = ["realtime", "historical", "discovery"];
  if (!validTypes.includes(matchType)) {
    throw new HttpsError("invalid-argument", `matchType must be one of: ${validTypes.join(", ")}.`);
  }

  // 4. Validate optional fields
  if (triggerSong !== undefined && triggerSong !== null) {
    if (typeof triggerSong.id !== "string" || typeof triggerSong.name !== "string" || typeof triggerSong.artistName !== "string") {
      throw new HttpsError("invalid-argument", "triggerSong must have id, name, and artistName as strings.");
    }
  }
  if (triggerArtist !== undefined && triggerArtist !== null) {
    if (typeof triggerArtist.id !== "string" || typeof triggerArtist.name !== "string") {
      throw new HttpsError("invalid-argument", "triggerArtist must have id and name as strings.");
    }
  }
  if (similarityScore !== undefined && similarityScore !== null) {
    if (typeof similarityScore !== "number" || similarityScore < 0 || similarityScore > 1) {
      throw new HttpsError("invalid-argument", "similarityScore must be a number between 0 and 1.");
    }
  }

  // 5. Check both users exist
  const [user1Doc, user2Doc] = await Promise.all([
    db.collection("users").doc(userIds[0]).get(),
    db.collection("users").doc(userIds[1]).get(),
  ]);
  if (!user1Doc.exists || !user2Doc.exists) {
    throw new HttpsError("not-found", "One or both users do not exist.");
  }

  // 6. Deduplicate — check if a match already exists between these users
  const existingMatches = await db
    .collection("matches")
    .where("userIds", "array-contains", userIds[0])
    .get();

  const duplicate = existingMatches.docs.find((doc) => {
    const data = doc.data();
    return data.userIds?.includes(userIds[1]);
  });

  if (duplicate) {
    // Return existing match instead of creating a duplicate
    return { matchId: duplicate.id, alreadyExisted: true };
  }

  // 7. Create the match document
  const matchData = {
    userIds,
    matchType,
    createdAt: FieldValue.serverTimestamp(),
  };
  if (triggerSong) {
    matchData.triggerSong = {
      id: triggerSong.id,
      name: triggerSong.name,
      artistName: triggerSong.artistName,
    };
  }
  if (triggerArtist) {
    matchData.triggerArtist = {
      id: triggerArtist.id,
      name: triggerArtist.name,
    };
  }
  if (typeof similarityScore === "number") {
    matchData.similarityScore = similarityScore;
  }

  const matchRef = await db.collection("matches").add(matchData);
  console.log(`Match ${matchRef.id} created between ${userIds[0]} and ${userIds[1]} (type: ${matchType})`);

  return { matchId: matchRef.id, alreadyExisted: false };
});

// MARK: - Match Notification

/**
 * Triggered when a new match document is created.
 * Sends a push notification to both matched users.
 */
export const onMatchCreated = onDocumentCreated(
  "matches/{matchId}",
  async (event) => {
    const matchData = event.data?.data();
    if (!matchData) return;

    const { userIds, triggerSong, triggerArtist, matchType } = matchData;
    if (!userIds || userIds.length !== 2) return;

    // Build notification content
    let title = "New Match!";
    let body = "Someone shares your music taste!";

    if (triggerSong?.name && triggerSong?.artistName) {
      body = `You both love "${triggerSong.name}" by ${triggerSong.artistName}`;
    } else if (triggerArtist?.name) {
      body = `You both love ${triggerArtist.name}`;
    } else if (matchType === "historical") {
      body = "You have similar music taste!";
    }

    // Send notification to each user — read token from private subcollection
    const notifications = userIds.map(async (userId) => {
      try {
        const tokenDoc = await db.collection("users").doc(userId).collection("private").doc("tokens").get();
        const deviceToken = tokenDoc.data()?.deviceToken;
        if (!deviceToken) return;

        await getMessaging().send({
          token: deviceToken,
          notification: { title, body },
          data: {
            type: "match",
            matchId: event.params.matchId,
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        });
      } catch (error) {
        console.error(
          `Failed to send match notification to ${userId}:`,
          error
        );
      }
    });

    await Promise.all(notifications);
  }
);

// MARK: - Message Notification

/**
 * Triggered when a new message is created in a match conversation.
 * Sends a push notification to the recipient (the user who didn't send the message).
 */
export const onMessageCreated = onDocumentCreated(
  "matches/{matchId}/messages/{messageId}",
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    const { senderId, text } = messageData;
    const matchId = event.params.matchId;

    // Get the match to find the other user
    const matchDoc = await db.collection("matches").doc(matchId).get();
    const matchData = matchDoc.data();
    if (!matchData?.userIds) return;

    const recipientId = matchData.userIds.find((id) => id !== senderId);
    if (!recipientId) return;

    // Get sender name for the notification
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.data()?.displayName || "Someone";

    // Get recipient device token from private subcollection
    const tokenDoc = await db.collection("users").doc(recipientId).collection("private").doc("tokens").get();
    const deviceToken = tokenDoc.data()?.deviceToken;
    if (!deviceToken) return;

    try {
      await getMessaging().send({
        token: deviceToken,
        notification: {
          title: senderName,
          body: text?.substring(0, 100) || "Sent you a message",
        },
        data: {
          type: "chat",
          matchId,
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });
    } catch (error) {
      console.error(
        `Failed to send message notification to ${recipientId}:`,
        error
      );
    }
  }
);

// MARK: - Account Cleanup

/**
 * Triggered when a user document is deleted.
 * Comprehensive cleanup: listening history, private tokens, matches,
 * messages within those matches, and friend requests.
 */
export const onUserDeleted = onDocumentDeleted(
  "users/{userId}",
  async (event) => {
    const userId = event.params.userId;
    console.log(`Cleaning up data for deleted user ${userId}`);

    // 1. Delete listening history subcollection
    const sessions = await db
      .collection("listeningHistory")
      .doc(userId)
      .collection("sessions")
      .listDocuments();

    if (sessions.length > 0) {
      const historyBatch = db.batch();
      for (const doc of sessions) {
        historyBatch.delete(doc);
      }
      historyBatch.delete(db.collection("listeningHistory").doc(userId));
      await historyBatch.commit();
      console.log(`Deleted ${sessions.length} listening history sessions`);
    }

    // 2. Delete private subcollection docs (tokens + profile)
    const privateDocs = await db.collection("users").doc(userId).collection("private").listDocuments();
    if (privateDocs.length > 0) {
      const privateBatch = db.batch();
      for (const doc of privateDocs) {
        privateBatch.delete(doc);
      }
      await privateBatch.commit();
      console.log(`Deleted ${privateDocs.length} private subcollection docs`);
    }

    // 3. Delete all matches involving this user and their messages
    const matchesSnapshot = await db
      .collection("matches")
      .where("userIds", "array-contains", userId)
      .get();

    for (const matchDoc of matchesSnapshot.docs) {
      // Delete all messages in this match first
      const messages = await matchDoc.ref.collection("messages").listDocuments();
      if (messages.length > 0) {
        // Firestore batches have a 500 operation limit
        const chunks = [];
        for (let i = 0; i < messages.length; i += 490) {
          chunks.push(messages.slice(i, i + 490));
        }
        for (const chunk of chunks) {
          const msgBatch = db.batch();
          for (const msg of chunk) {
            msgBatch.delete(msg);
          }
          await msgBatch.commit();
        }
      }
      // Delete the match document itself
      await matchDoc.ref.delete();
    }
    console.log(`Deleted ${matchesSnapshot.docs.length} matches and their messages`);

    // 4. Delete friend requests (sent or received)
    const sentRequests = await db
      .collection("friendRequests")
      .where("senderId", "==", userId)
      .get();

    const receivedRequests = await db
      .collection("friendRequests")
      .where("receiverId", "==", userId)
      .get();

    const allRequests = [...sentRequests.docs, ...receivedRequests.docs];
    if (allRequests.length > 0) {
      const chunks = [];
      for (let i = 0; i < allRequests.length; i += 490) {
        chunks.push(allRequests.slice(i, i + 490));
      }
      for (const chunk of chunks) {
        const reqBatch = db.batch();
        for (const doc of chunk) {
          reqBatch.delete(doc.ref);
        }
        await reqBatch.commit();
      }
    }
    console.log(`Deleted ${allRequests.length} friend requests`);

    // 5. Delete reports filed by this user
    const reportsByUser = await db
      .collection("reports")
      .where("reporterId", "==", userId)
      .get();

    if (reportsByUser.docs.length > 0) {
      const chunks = [];
      for (let i = 0; i < reportsByUser.docs.length; i += 490) {
        chunks.push(reportsByUser.docs.slice(i, i + 490));
      }
      for (const chunk of chunks) {
        const reportBatch = db.batch();
        for (const doc of chunk) {
          reportBatch.delete(doc.ref);
        }
        await reportBatch.commit();
      }
    }
    console.log(`Deleted ${reportsByUser.docs.length} reports by user`);

    // 6. blockedUserIds cleanup skipped — blocked lists are now stored in
    //    users/{uid}/private/profile subcollections which cannot be efficiently
    //    queried across all users. Stale blocked IDs are harmless (the blocked
    //    user no longer exists) and will not affect app behavior.

    // 7. Delete imported playlists subcollection
    const playlists = await db
      .collection("users")
      .doc(userId)
      .collection("importedPlaylists")
      .listDocuments();

    if (playlists.length > 0) {
      const playlistBatch = db.batch();
      for (const doc of playlists) {
        playlistBatch.delete(doc);
      }
      await playlistBatch.commit();
    }

    console.log(`Cleanup complete for user ${userId}`);
  }
);

// MARK: - Debug: Seed Test Match (Callable)

/**
 * Creates a test user and match for debugging purposes.
 * Uses admin SDK to bypass security rules.
 * Should be removed or disabled before production release.
 *
 * @param {Object} data
 * @param {string} data.testUserId - The test user ID to create.
 * @param {Object} data.triggerSong - { id, name, artistName }
 * @returns {{ matchId: string }}
 */
export const seedTestMatch = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  const callerUid = request.auth.uid;
  const { testUserId, triggerSong } = request.data;

  if (!testUserId || !triggerSong) {
    throw new HttpsError("invalid-argument", "testUserId and triggerSong are required.");
  }

  // Rate limit: max 5 seed matches per hour
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
  const recentMatches = await db
    .collection("matches")
    .where("userIds", "array-contains", callerUid)
    .where("createdAt", ">=", oneHourAgo)
    .count()
    .get();

  if (recentMatches.data().count >= 5) {
    throw new HttpsError("resource-exhausted", "Too many test matches. Try again later.");
  }

  // Create test user doc via admin SDK (bypasses rules)
  await db.collection("users").doc(testUserId).set({
    displayName: "Resonance Tester",
    email: "test@resonance.app",
    authProvider: "apple",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Create match via admin SDK
  const matchRef = await db.collection("matches").add({
    userIds: [callerUid, testUserId],
    matchType: "realtime",
    triggerSong: {
      id: triggerSong.id,
      name: triggerSong.name,
      artistName: triggerSong.artistName,
    },
    createdAt: FieldValue.serverTimestamp(),
  });

  // Seed an initial message from the caller
  await matchRef.collection("messages").add({
    senderId: callerUid,
    text: `Hey! We both love ${triggerSong.name}!`,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  console.log(`Debug: Seeded test match ${matchRef.id} for ${callerUid}`);
  return { matchId: matchRef.id };
});
