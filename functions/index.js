const { setGlobalOptions } = require("firebase-functions");
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");

admin.initializeApp();
const db = getFirestore();

setGlobalOptions({ maxInstances: 10 });

//--------------------------------------------
// ✅ HELPER: TYPE SCHÖN UMWANDELN
//--------------------------------------------
function getTypeLabel(type) {
  if (type.toLowerCase() === "alt") return "Altkönig schießen";
  if (type.toLowerCase() === "jung") return "Jungkönig schießen";
  return type;
}

//--------------------------------------------
// ✅ HELPER: TEILE SCHÖN FORMATIEREN
//--------------------------------------------
function getPartLabel(key) {
  switch (key) {
    case "Krone": return "Krone 👑";
    case "Zepter": return "Zepter ✨";
    case "Reichsapfel": return "Reichsapfel 🍎";
    case "Flügel links": return "Flügel links 🪽";
    case "Flügel rechts": return "Flügel rechts 🪽";
    case "Adler": return "Adler 🦅";
    default: return key;
  }
}

//--------------------------------------------
// ✅ ADLER EVENTS (ALT / JUNG)
//--------------------------------------------
exports.adlerEventsPush = onDocumentUpdated(
  "adler_events/{location}/events/{type}",
  async (event) => {

    const before = event.data.before.data();
    const after = event.data.after.data();

    const location = event.params.location;
    const type = event.params.type;

    const typeLabel = getTypeLabel(type);

    //--------------------------------------------
    // ✅ ADLERSCHIESSEN START
    //--------------------------------------------
    if (!before.isActive && after.isActive) {
      await sendPush(
        location,
        `🪶 ${typeLabel}`,
        `${typeLabel} läuft jetzt!`
      );
    }

    //--------------------------------------------
    // ✅ TREFFER: ALLE TEILE ERKENNEN ✅
    //--------------------------------------------
    const beforeResults = before.results || {};
    const afterResults = after.results || {};

    for (const key of Object.keys(afterResults)) {

      const beforePart = beforeResults[key];
      const afterPart = afterResults[key];

      const beforeShots = beforePart?.shots || 0;
      const afterShots = afterPart?.shots || 0;

      if (afterShots > beforeShots) {

        const partLabel = getPartLabel(key);

        await sendPush(
          location,
          "🎯 Treffer!",
          `${typeLabel}: ${partLabel} getroffen!`
        );

        break; // ✅ verhindert doppelten Push
      }
    }

    //--------------------------------------------
    // ✅ NEUER KÖNIG
    //--------------------------------------------
    if (!before.kingName && after.kingName) {
      await sendPush(
        location,
        "👑 Neuer König!",
        `${after.kingName} ist neuer König (${typeLabel})`
      );
    }
  }
);

//--------------------------------------------
// ✅ FESTIVAL START
//--------------------------------------------
exports.festivalStartPush = onDocumentUpdated(
  "festivals/{festivalId}",
  async (event) => {

    const before = event.data.before.data();
    const after = event.data.after.data();

    const id = event.params.festivalId;

    if (before.isLive !== true && after.isLive === true) {
      await sendPush(
        id,
        "🎉 Heute geht's los!",
        `${after.name ?? id} startet jetzt!`
      );
    }
  }
);

//--------------------------------------------
// ✅ HELPER: PUSH MIT NAMEN
//--------------------------------------------
async function sendPush(location, title, body) {

  let festivalName = location;

  try {
    const doc = await db.collection("festivals").doc(location).get();
    if (doc.exists && doc.data().name) {
      festivalName = doc.data().name;
    }
  } catch (e) {
    console.log("⚠️ Name konnte nicht geladen werden");
  }

  await admin.messaging().send({
    topic: `festival_${location}`,
    notification: {
      title,
      body: `${festivalName}\n${body}`,
    },
  });

  console.log(`✅ Push für ${festivalName}: ${title}`);
}
//--------------------------------------------
// ✅ ADMIN NEWS PUSH (CREATE ✅)
//--------------------------------------------
exports.adminNewsCreatePush = onDocumentCreated(
  "admin_news/{docId}",
  async (event) => {

    const data = event.data.data();

    await admin.messaging().send({
      topic: "all",
      notification: {
        title: `📢 ${data.title}`,
        body: data.content,
      },
    });

    console.log("✅ Admin Push (CREATE):", data.title);
  }
);

//--------------------------------------------
// ✅ ADMIN NEWS PUSH (UPDATE ✅)
//--------------------------------------------
exports.adminNewsUpdatePush = onDocumentUpdated(
  "admin_news/{docId}",
  async (event) => {

    const before = event.data.before.data();
    const after = event.data.after.data();

    if (
      before.title !== after.title ||
      before.content !== after.content
    ) {
      await admin.messaging().send({
        topic: "all",
        notification: {
          title: `📢 ${after.title}`,
          body: after.content,
        },
      });

      console.log("✅ Admin Push (UPDATE):", after.title);
    }
  }
);
