const { setGlobalOptions } = require("firebase-functions");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

admin.initializeApp();
const db = getFirestore();

setGlobalOptions({ maxInstances: 10, region: "europe-west3" });

//====================================================
// ✅ HELPER: PUSH AN EIN EVENT-TOPIC
//====================================================
async function sendEventPush(eventId, title, body, extraData = {}) {

  let eventName = eventId;

  try {
    const doc = await db.collection("events").doc(eventId).get();
    if (doc.exists && doc.data().name) {
      eventName = doc.data().name;
    }
  } catch (e) {
    console.log("Name konnte nicht geladen werden:", e.message);
  }

  try {
    await admin.messaging().send({
      topic: `Event_${eventId}`,
      notification: {
        title,
        body: `${eventName}\n${body}`,
      },
      data: {
        eventId,
        ...extraData,
      },
    });

    console.log(`Push für ${eventName}: ${title}`);
  } catch (e) {
    console.error(`Push fehlgeschlagen für ${eventId}:`, e.message);
  }
}

//====================================================
// ✅ ERINNERUNG: FAVORISIERTES EVENT STEHT HEUTE AN
//====================================================
// Läuft täglich um 08:00 Uhr (Europe/Berlin).
// Pusht ans Event_<id>-Topic, das Nutzer beim
// Favorisieren automatisch abonnieren (siehe FavoriteService).
//----------------------------------------------------
exports.eventStartingTodayReminder = onSchedule(
  {
    schedule: "0 8 * * *",
    timeZone: "Europe/Berlin",
  },
  async () => {

    const now = new Date();
    const todayKey = now.toISOString().slice(0, 10);

    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);

    const snapshot = await db
      .collection("events")
      .where("startDate", ">=", Timestamp.fromDate(startOfDay))
      .where("startDate", "<=", Timestamp.fromDate(endOfDay))
      .get();

    if (snapshot.empty) {
      console.log("Keine Events, die heute starten.");
      return;
    }

    for (const doc of snapshot.docs) {
      const data = doc.data();

      if (data.startReminderSentOn === todayKey) {
        continue;
      }

      await sendEventPush(
        doc.id,
        "🎉 Heute geht's los!",
        `${data.name ?? doc.id} startet heute!`,
        { type: "event_start" }
      );

      await doc.ref.update({ startReminderSentOn: todayKey });
    }

    console.log(`Erinnerungen für ${snapshot.size} Event(s) geprüft.`);
  }
);

//====================================================
// ✅ ADMIN NEWS PUSH (CREATE)
//====================================================
exports.adminNewsCreatePush = onDocumentCreated(
  "admin_news/{docId}",
  async (event) => {

    const data = event.data.data();

    try {
      await admin.messaging().send({
        topic: "all",
        notification: {
          title: `📢 ${data.title}`,
          body: data.content,
        },
        data: {
          type: "admin_news",
          docId: event.params.docId,
        },
      });

      console.log("Admin Push (CREATE):", data.title);
    } catch (e) {
      console.error("Admin Push (CREATE) fehlgeschlagen:", e.message);
    }
  }
);

//====================================================
// ✅ ADMIN NEWS PUSH (UPDATE)
//====================================================
exports.adminNewsUpdatePush = onDocumentUpdated(
  "admin_news/{docId}",
  async (event) => {

    const before = event.data.before.data();
    const after = event.data.after.data();

    if (
      before.title !== after.title ||
      before.content !== after.content
    ) {
      try {
        await admin.messaging().send({
          topic: "all",
          notification: {
            title: `📢 ${after.title}`,
            body: after.content,
          },
          data: {
            type: "admin_news",
            docId: event.params.docId,
          },
        });

        console.log("Admin Push (UPDATE):", after.title);
      } catch (e) {
        console.error("Admin Push (UPDATE) fehlgeschlagen:", e.message);
      }
    }
  }
);