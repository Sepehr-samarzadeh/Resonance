// Cloud Functions for Resonance
// Handles push notifications for new matches and messages.

import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();

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

    // Send notification to each user
    const notifications = userIds.map(async (userId) => {
      try {
        const userDoc = await db.collection("users").doc(userId).get();
        const userData = userDoc.data();
        if (!userData?.deviceToken) return;

        await getMessaging().send({
          token: userData.deviceToken,
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

    // Get recipient device token
    const recipientDoc = await db.collection("users").doc(recipientId).get();
    const recipientData = recipientDoc.data();
    if (!recipientData?.deviceToken) return;

    try {
      await getMessaging().send({
        token: recipientData.deviceToken,
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
 * Cleans up orphaned data: listening history subcollection.
 */
export const onUserDeleted = onDocumentDeleted(
  "users/{userId}",
  async (event) => {
    const userId = event.params.userId;

    // Delete listening history subcollection
    const sessions = await db
      .collection("listeningHistory")
      .doc(userId)
      .collection("sessions")
      .listDocuments();

    const batch = db.batch();
    for (const doc of sessions) {
      batch.delete(doc);
    }
    // Delete the parent listening history doc
    batch.delete(db.collection("listeningHistory").doc(userId));

    await batch.commit();
    console.log(`Cleaned up data for deleted user ${userId}`);
  }
);
