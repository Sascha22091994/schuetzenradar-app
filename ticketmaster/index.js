const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");

admin.initializeApp();
const db = getFirestore();

setGlobalOptions({ maxInstances: 10, region: "europe-west3" });

//====================================================
// ✅ KATEGORIE-NORMALISIERUNG
//====================================================
const VALID_CATEGORIES = new Set([
  "schuetzenfest",
  "konzert",
  "festival",
  "stadtfest",
  "markt",
  "food",
  "sport",
  "familie",
  "theater_comedy",
  "sonstiges",
  "fuehrung",
  "workshop",
  // ✅ NEU (Tier 1)
  "kunst",
  "natur",
  // ✅ NEU: eigener Kino-Chip + Community-Treffs
  "kino",
  "treffen",
]);

// ✅ TIER 3: Service-/Behörden-"Events", die kein Freizeit-Event sind und
// gar nicht erst importiert werden sollen (Blutspende, Sprechstunden etc.).
// Wird in jedem Importer via isNoiseEvent() geprüft.
const NOISE_KEYWORDS = [
  "sprechstunde",
  "bürgersprechstunde",
  "buergersprechstunde",
  "blutspende",
  "blutspendetermin",
  "patientenverfügung",
  "freiwilligen-agentur",
  "freiwilligenagentur",
  "bürgerservice",
  "buergerservice",
];

function isNoiseEvent(text) {
  const t = (text || "").toLowerCase();
  return NOISE_KEYWORDS.some((k) => t.includes(k));
}

function normalizeCategory(rawCategory) {
  const cat = (rawCategory || "").toLowerCase().trim();

  if (cat === "weihnachtsmarkt") return "markt";
  if (cat === "comedy" || cat === "theater") return "theater_comedy";
  if (cat === "fuehrung" || cat === "führung") return "fuehrung";
  if (cat === "workshop" || cat === "vortrag") return "workshop";

  // ✅ NEU (Tier 1): Sammel-Aliasse, damit egal welcher Importer diese
  // Rohwerte liefert, sie sicher auf die neuen Kategorien landen.
  if (
    cat === "kunst" ||
    cat === "ausstellung" ||
    cat === "vernissage" ||
    cat === "galerie" ||
    cat === "malerei"
  ) {
    return "kunst";
  }
  if (
    cat === "natur" ||
    cat === "wandern" ||
    cat === "wanderung" ||
    cat === "spaziergang"
  ) {
    return "natur";
  }

  // ✅ Bonus-Fix: "nachtleben"/"party" war nie ein gültiger Enum-Wert und
  // fiel bisher still in "sonstiges". Party-Events landen jetzt in "festival".
  if (cat === "nachtleben" || cat === "party") return "festival";

  if (VALID_CATEGORIES.has(cat)) return cat;

  if (cat) {
    console.log(`Unbekannte Kategorie "${cat}" -> Fallback "sonstiges"`);
  }
  return "sonstiges";
}

//====================================================
// ✅ TITEL-BASIERTE ZUORDNUNG (Fallback)
//====================================================
// Wird genutzt, wenn die Quell-Kategorie eines Events "sonstiges" ergibt.
// Durchsucht Titel (+Beschreibung) nach eindeutigen Signalen. Reihenfolge =
// Priorität: spezifisch vor generisch, damit z.B. Kunsthandwerk NICHT als
// Kunst, sondern als Markt landet. Bewusst konservativ, um Fehlzuordnungen
// bei generischen Wörtern (z.B. "Tour" in Konzert-Tourneen) zu vermeiden.
function mapTextToCategory(text) {
  const t = (text || "").toLowerCase();
  const has = (...ks) => ks.some((k) => t.includes(k));

  if (has("schützenfest")) return "schuetzenfest";
  if (has("weihnachtsmarkt", "adventsmarkt", "nikolausmarkt")) return "markt";
  if (has("kunsthandwerk", "handgemachtes")) return "markt";
  if (has("flohmarkt", "trödelmarkt", "wochenmarkt", "bauernmarkt",
          "herbstmarkt", "staudenbörse", "verkaufsoffener sonntag")) return "markt";

  if (has("schnitzeltag", "grünkohl", "weinfest", "weintage", "weinprobe",
          "bierprobe", "kartoffelfest", "backtag", "spargel", "street food",
          "kulinar", "schlemmer")) return "food";

  // Kinder-Kino VOR generischem Kino, damit es in "familie" statt "kino" landet
  if (has("kinderkino", "kinofürkids", "kindersommerkino", "kinderfilm")) return "familie";
  if (has("kino", "autokino", "filmvorführung", "filmnacht")) return "kino";

  if (has("ausstellung", "vernissage", "galerie", "zeichentreff",
          "sonntagsatelier", "atelier", "skulptur", "kunstpunkt", "kunststele",
          "maltreff", "kunstspäti", "malerei", "genremalerei")) return "kunst";

  if (has("konzert", "chorkonzert", "orgelvesper", "orgelfeierstunde", "orgel",
          "liederabend", "big band", "big-band", "sinfonie", "philharmon",
          "kammermusik", "jazzmatinee")) return "konzert";

  if (has("theater", "comedy", "kabarett", "kleinkunst", "poetry slam",
          "science slam", "stand-up", "stand up", "musical", "travestie",
          "mixshow", "improtheater", "laienbühne")) return "theater";

  if (has("wanderung", "wandern", "spaziergang", "eifelverein", "naturführung",
          "kräuterwanderung", "nordic walking", "waldbaden", "lernort natur",
          "natur.pur", "natur-tour", "naturkundliche")) return "natur";

  // Nur eindeutige Führungs-Begriffe (KEIN generisches "tour" -> sonst würden
  // Konzert-Tourneen wie "... Tour 2026" fälschlich als Führung gelten)
  if (has("stadtführung", "stadtrundgang", "stadtrundfahrt", "kirchenführung",
          "bibliotheksführung", "taschenlampenführung", "werksbesichtigung",
          "besichtigung", "rundgang", "führung")) return "fuehrung";

  if (has("familienfrühstück", "puppentheater", "märchen", "abenteuermuseum",
          "explorado", "maislabyrinth", "ferienprogramm", "kulturrucksack")) return "familie";

  if (has("triathlon", "volkslauf", "parkrun", "turnier", "nordic",
          "mitternachtsschwimmen", "moonlight-schwimmen", "moonlight schwimmen",
          "boule")) return "sport";

  if (has("workshop", "seminar", "vortrag", "schreibwerkstatt",
          "erste-hilfe-kurs")) return "workshop";

  // ✅ NEU: Treffen & Gruppen – wiederkehrende Community-/Nachbarschafts-
  // Treffs. Bewusst als LETZTE Regel (niedrigste Priorität), damit echte
  // Kategorien Vorrang haben. Behörden-/Service-Noise (Blutspende,
  // Sprechstunde, Beratung) wird davor über isNoiseEvent() gelöscht.
  if (has("kreativkreis", "kreativgruppe", "kreatives plotten",
          "strickcafé", "strickcafe", "stricktreff", "handarbeitsrunde",
          "häkeln und stricken", "näh-café", "näh-cafe", "nähcafé",
          "spieletreff", "spiele-treff", "spieleabend", "spielenachmittag",
          "pen & paper", "bingonachmittag", "bingoabend", "bingo",
          "seniorennachmittag", "seniorentreff", "treffpunkt bank",
          "café für die seele", "cafe für die seele", "begegnungscafé",
          "begegnungscafe", "repair café", "repair-café", "repaircafé",
          "repair cafe", "sprachtreff", "aktionsnachmittag", "plauderbank",
          "plaudern", "stammtisch", "gesprächskreis", "lesekreis",
          "frühstückstreffen", "handarbeit", "mantra-singen",
          "offener kaffee", "kaffeepause", "austauschtreff",
          "queer60plus", "schachtreff", "schach für", "skat-schach",
          "preis-skat", "retro gaming treff")) return "treffen";

  return "sonstiges";
}

//====================================================
// ✅ HELPER: KONTROLLIERTE PARALLELVERARBEITUNG
//====================================================
async function runWithConcurrency(items, limit, worker) {
  const results = [];
  let index = 0;

  async function runNext() {
    while (index < items.length) {
      const currentIndex = index++;
      try {
        const result = await worker(items[currentIndex], currentIndex);
        results[currentIndex] = result;
      } catch (e) {
        results[currentIndex] = null;
        console.error("Worker-Fehler:", e.message);
      }
    }
  }

  const workers = Array.from(
    { length: Math.min(limit, items.length) },
    () => runNext()
  );

  await Promise.all(workers);

  return results;
}

//====================================================
// ✅ HELPER: FIRESTORE BATCHED WRITES
//====================================================
async function batchWriteEvents(entries) {
  const CHUNK_SIZE = 450;
  let written = 0;

  for (let i = 0; i < entries.length; i += CHUNK_SIZE) {
    const chunk = entries.slice(i, i + CHUNK_SIZE);
    const batch = db.batch();

    for (const entry of chunk) {
      const ref = db.collection("events").doc(entry.docId);
      batch.set(ref, entry.data, { merge: true });
    }

    await batch.commit();
    written += chunk.length;
    console.log(`Batch geschrieben: ${written}/${entries.length}`);
  }

  return written;
}

//====================================================
// ✅ IMPORT: TICKETMASTER
//====================================================
async function importTicketmasterEvents() {
  // ⚠️ Sicherheitshinweis: API-Key liegt hier im Klartext.
  const apiKey = "aDhsArMmjLDq6JiyBPfLAJ6h7LL1sHtC";

  const urls = [
    `https://app.ticketmaster.com/discovery/v2/events.json?countryCode=DE&classificationName=music&size=200&apikey=${apiKey}`,
    `https://app.ticketmaster.com/discovery/v2/events.json?countryCode=DE&keyword=festival&size=200&apikey=${apiKey}`,
    `https://app.ticketmaster.com/discovery/v2/events.json?countryCode=DE&keyword=open%20air&size=200&apikey=${apiKey}`,
    `https://app.ticketmaster.com/discovery/v2/events.json?countryCode=DE&keyword=rock&size=200&apikey=${apiKey}`,
  ];

  const entries = [];
  let errorCount = 0;

  for (const url of urls) {
    let data;

    try {
      const response = await fetch(url);
      data = await response.json();
    } catch (e) {
      console.error("Ticketmaster: Request fehlgeschlagen für URL", url, e.message);
      continue;
    }

    const events = data._embedded?.events ?? [];

    for (const event of events) {
      try {
        const venue = event._embedded?.venues?.[0];

        const latitude = venue?.location?.latitude
          ? parseFloat(venue.location.latitude)
          : 0;

        const longitude = venue?.location?.longitude
          ? parseFloat(venue.location.longitude)
          : 0;

        const eventName = event.name?.toLowerCase() ?? "";
        const segment = event.classifications?.[0]?.segment?.name?.toLowerCase() ?? "";
        const genre = event.classifications?.[0]?.genre?.name?.toLowerCase() ?? "";

        // ✅ TIER 3: Service-/Behörden-"Events" gar nicht importieren
        if (isNoiseEvent(eventName)) {
          continue;
        }

        let rawCategory = "event";
        let subcategory = genre;

        const festivalKeywords = [
          "festival", "lollapalooza", "parookaville", "hurricane",
          "southside", "wacken", "rock am ring", "rock im park",
          "airbeat", "nature one", "tomorrowland", "deichbrand", "open air",
        ];

        if (festivalKeywords.some((keyword) => eventName.includes(keyword))) {
          rawCategory = "festival";
        } else if (segment.includes("music")) {
          rawCategory = "konzert";
        }

        if (genre.includes("comedy") || eventName.includes("comedy")) {
          rawCategory = "comedy";
        }

        if (segment.includes("sport")) {
          rawCategory = "sport";
        }

        if (segment.includes("family")) {
          rawCategory = "familie";
        }

        if (
          segment.includes("arts") ||
          genre.includes("theater") ||
          genre.includes("theatre")
        ) {
          rawCategory = "theater";
        }

        if (genre.includes("workshop") || eventName.includes("workshop")) {
          rawCategory = "workshop";
        }

        if (
          genre.includes("tour") ||
          eventName.includes("führung") ||
          eventName.includes("tour")
        ) {
          rawCategory = "fuehrung";
        }

        if (genre.includes("rock")) subcategory = "rock";
        if (genre.includes("pop")) subcategory = "pop";
        if (genre.includes("hip-hop") || genre.includes("hip hop") || genre.includes("rap")) subcategory = "hiphop";
        if (genre.includes("dance") || genre.includes("electronic") || genre.includes("techno") || genre.includes("house")) subcategory = "electro";
        if (genre.includes("country")) subcategory = "country";
        if (genre.includes("classical") || genre.includes("klassik")) subcategory = "klassik";
        if (genre.includes("metal")) subcategory = "metal";
        if (genre.includes("jazz")) subcategory = "jazz";

        const category = normalizeCategory(rawCategory);

        let startDate = event.dates?.start?.localDate;
        let firebaseDate = null;

        if (startDate) {
          firebaseDate = admin.firestore.Timestamp.fromDate(new Date(startDate));
        }

        entries.push({
          docId: event.id,
          data: {
            name: event.name ?? "",
            address: venue?.name ?? "",
            category,
            subcategory,
            ticketmasterGenre: genre,
            ticketmasterSegment: segment,
            source: "ticketmaster",
            description: event.info ?? event.pleaseNote ?? "",
            latitude,
            longitude,
            startDate: firebaseDate,
            endDate: firebaseDate,
            flyerUrl: event.images?.[0]?.url ?? "",
            images: event.images ? event.images.map((img) => img.url) : [],
            ticketUrl: event.url ?? "",
            venueName: venue?.name ?? "",
            city: venue?.city?.name ?? "",
            country: venue?.country?.name ?? "",
            isHighlight: false,
            importedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        });
      } catch (e) {
        errorCount++;
        console.error("Ticketmaster: Event-Fehler", event?.id, e.message);
      }
    }
  }

  const written = await batchWriteEvents(entries);
  console.log(`Ticketmaster: ${written} importiert, ${errorCount} Fehler`);
  return written;
}

//====================================================
// ✅ IMPORT: MÜHLENKREIS (ET4)
//====================================================
async function importMuehlenkreisEvents() {
  const url =
    "https://meta.et4.de/rest.ashx/search/?type=Event&experience=minden-luebbecke&mkt=de&maxresponsetime=0&unique=true&mode=next_months,6&sort=start+asc&unrollIntervals=true&limit=500&template=ET2014A_LIGHT.json";

  let data;

  try {
    const response = await fetch(url);
    data = await response.json();
  } catch (e) {
    console.error("Mühlenkreis: Request fehlgeschlagen", e.message);
    return 0;
  }

  const events = data.items || [];
  const entries = [];

  for (const event of events) {
    try {
      const firstInterval = event.timeIntervals?.[0];

      if (!firstInterval) continue;

      const startDate = firstInterval.start
        ? admin.firestore.Timestamp.fromDate(new Date(firstInterval.start))
        : null;

      const endDate = firstInterval.end
        ? admin.firestore.Timestamp.fromDate(new Date(firstInterval.end))
        : null;

      const latitude = event.geo?.main?.latitude || 0;
      const longitude = event.geo?.main?.longitude || 0;
      const imageUrl = event.media_objects?.[0]?.url || "";

      const title = (event.title || "").toLowerCase();
      const description = (event.texts?.[0]?.value || "").toLowerCase();
      const categoryText = (event.categories || []).join(" ").toLowerCase();
      const searchText = `${title} ${description} ${categoryText}`;

      // ✅ TIER 3: Service-/Behörden-"Events" gar nicht importieren
      if (isNoiseEvent(searchText)) {
        continue;
      }

      let rawCategory = "sonstiges";

      if (searchText.includes("schützenfest")) {
        rawCategory = "schuetzenfest";
      } else if (
        searchText.includes("weihnachtsmarkt") ||
        searchText.includes("adventsmarkt") ||
        searchText.includes("nikolausmarkt")
      ) {
        rawCategory = "weihnachtsmarkt";
      } else if (
        searchText.includes("stadtfest") ||
        searchText.includes("dorffest") ||
        searchText.includes("sommerfest") ||
        searchText.includes("familientag") ||
        searchText.includes("heimatfest") ||
        searchText.includes("festwoche") ||
        searchText.includes("volksfest")
      ) {
        rawCategory = "stadtfest";
      } else if (
        searchText.includes("wochenmarkt") ||
        searchText.includes("markt") ||
        searchText.includes("trödelmarkt") ||
        searchText.includes("flohmarkt") ||
        searchText.includes("bauernmarkt") ||
        searchText.includes("kunsthandwerk") // ✅ vor kunst, bleibt Markt
      ) {
        rawCategory = "markt";
      } else if (
        searchText.includes("food") ||
        searchText.includes("genuss") ||
        searchText.includes("gastronomie") ||
        searchText.includes("backtag") ||
        searchText.includes("spargel") ||
        searchText.includes("wein") ||
        searchText.includes("bier") ||
        searchText.includes("street food") ||
        searchText.includes("kulinar")
      ) {
        rawCategory = "food";
      } else if (
        // ✅ NEU (Tier 1): Kunst & Ausstellung
        searchText.includes("ausstellung") ||
        searchText.includes("vernissage") ||
        searchText.includes("galerie") ||
        searchText.includes("malerei") ||
        searchText.includes("genremalerei") ||
        searchText.includes("skulptur") ||
        searchText.includes("bildhauer") ||
        searchText.includes("atelier") ||
        searchText.includes("kunstausstellung")
      ) {
        rawCategory = "kunst";
      } else if (
        searchText.includes("konzert") ||
        searchText.includes("live") ||
        searchText.includes("musik") ||
        searchText.includes("open air") ||
        searchText.includes("band") ||
        searchText.includes("chor") ||
        searchText.includes("orchester") ||
        searchText.includes("orgel") ||
        searchText.includes("liederabend") ||
        searchText.includes("picknick-konzert")
      ) {
        rawCategory = "konzert";
      } else if (searchText.includes("festival")) {
        rawCategory = "festival";
      } else if (
        // ✅ NEU (Tier 1): Natur & Wandern — vor sport
        searchText.includes("wanderung") ||
        searchText.includes("wandern") ||
        searchText.includes("spaziergang") ||
        searchText.includes("eifelverein") ||
        searchText.includes("naturführung") ||
        searchText.includes("kräuterwanderung")
      ) {
        rawCategory = "natur";
      } else if (
        searchText.includes("sport") ||
        searchText.includes("lauf") ||
        searchText.includes("marathon") ||
        searchText.includes("fußball") ||
        searchText.includes("fussball") ||
        searchText.includes("turnier") ||
        searchText.includes("radtour")
      ) {
        rawCategory = "sport";
      } else if (
        searchText.includes("kinder") ||
        searchText.includes("familie") ||
        searchText.includes("familien") ||
        searchText.includes("spiel") ||
        searchText.includes("explorado") ||
        searchText.includes("abenteuermuseum") ||
        searchText.includes("märchen") ||
        searchText.includes("puppentheater") ||
        searchText.includes("maislabyrinth") ||
        searchText.includes("ferienprogramm")
      ) {
        rawCategory = "familie";
      } else if (
        searchText.includes("führung") ||
        searchText.includes("fuehrung") ||
        searchText.includes("stadtführung") ||
        searchText.includes("rundgang") ||
        searchText.includes("nachtwächter") ||
        searchText.includes("besichtigung") || // ✅ NEU
        searchText.includes("tour")
      ) {
        rawCategory = "fuehrung";
      } else if (
        searchText.includes("workshop") ||
        searchText.includes("kurs") ||
        searchText.includes("vortrag") ||
        searchText.includes("seminar") ||
        searchText.includes("yoga") ||
        searchText.includes("achtsamkeit") // ✅ NEU
      ) {
        rawCategory = "workshop";
      } else if (
        searchText.includes("kino") ||
        searchText.includes("autokino")
      ) {
        rawCategory = "kino";
      } else if (
        searchText.includes("theater") ||
        searchText.includes("comedy") ||
        searchText.includes("kabarett") ||
        searchText.includes("kleinkunst") ||
        searchText.includes("poetry slam") ||
        searchText.includes("lesung")
      ) {
        rawCategory = "theater";
      }

      const category = (() => {
        const c = normalizeCategory(rawCategory);
        // ✅ FALLBACK auf title-basierte Zuordnung, falls die Chain oben
        // nichts Passendes gefunden hat (fängt z.B. Kino / Ausstellung).
        return c === "sonstiges"
          ? normalizeCategory(mapTextToCategory(searchText))
          : c;
      })();

      entries.push({
        docId: `et4_${event.id}`,
        data: {
          name: event.title || "",
          address: `${event.street || ""}, ${event.zip || ""} ${event.city || ""}`,
          city: event.city || "",
          country: event.country || "",
          category,
          subcategory: (event.categories || []).join(", "),
          description: event.texts?.[0]?.value || "",
          latitude,
          longitude,
          startDate,
          endDate,
          flyerUrl: imageUrl,
          images: imageUrl ? [imageUrl] : [],
          ticketUrl: "",
          venueName: event.name || "",
          isHighlight: event.highlight || false,
          source: "muehlenkreis",
          et4Id: event.id,
          importedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      console.error("ET4 Fehler", event.id, e.message);
    }
  }

  const written = await batchWriteEvents(entries);
  return written;
}

//====================================================
// ✅ IMPORT: NRW DATA HUB (destination.one, landesweit)
//====================================================
function mapNRWCategory(categoriesArray) {
  const cat = (categoriesArray || []).join(" ").toLowerCase();

  if (cat.includes("schützenfest")) return "schuetzenfest";

  if (cat.includes("weihnachtsmarkt") || cat.includes("adventsmarkt")) {
    return "markt";
  }

  if (
    cat.includes("stadtfest") ||
    cat.includes("kirmes") ||
    cat.includes("jahrmarkt") ||
    cat.includes("fest/ball") ||
    cat.includes("volksfest") ||
    cat.includes("dorffest") ||
    cat.includes("brauchtum")
  ) {
    return "stadtfest";
  }

  // ✅ Kunsthandwerk(er)markt bleibt Markt, NICHT Kunst -> vor der kunst-Regel
  if (
    cat.includes("markt") ||
    cat.includes("flohmarkt") ||
    cat.includes("kunsthandwerk") ||
    cat.includes("handgemachtes")
  ) {
    return "markt";
  }

  if (
    cat.includes("kulinar") ||
    cat.includes("wein") ||
    cat.includes("bier") ||
    cat.includes("genuss") ||
    cat.includes("gastronomie")
  ) {
    return "food";
  }

  // ✅ NEU (Tier 1): Kunst & Ausstellung — größter Cluster im "sonstiges"-Berg
  if (
    cat.includes("ausstellung") ||
    cat.includes("vernissage") ||
    cat.includes("galerie") ||
    cat.includes("malerei") ||
    cat.includes("genremalerei") ||
    cat.includes("impressionist") ||
    cat.includes("skulptur") ||
    cat.includes("bildhauer") ||
    cat.includes("aquarell") ||
    cat.includes("atelier") ||
    cat.includes("kunst") // nach kunsthandwerk-Ausschluss oben unproblematisch
  ) {
    return "kunst";
  }

  if (
    cat.includes("konzert") ||
    cat.includes("musik") ||
    cat.includes("chor") ||
    cat.includes("orchester") ||
    cat.includes("orgel") ||
    cat.includes("liederabend") ||
    cat.includes("sinfonie") ||
    cat.includes("philharmon")
  ) {
    return "konzert";
  }

  if (cat.includes("festival")) {
    return "festival";
  }

  // ✅ NEU (Tier 1): Natur & Wandern — vor "sport", damit Wanderungen nicht
  // fälschlich als Sport landen (wie bisher).
  if (
    cat.includes("wanderung") ||
    cat.includes("wandern") ||
    cat.includes("spaziergang") ||
    cat.includes("naturführung") ||
    cat.includes("naturerlebnis") ||
    cat.includes("kräuterwanderung") ||
    cat.includes("nachtwanderung") ||
    cat.includes("eifelverein") ||
    cat.includes("pilgern")
  ) {
    return "natur";
  }

  if (
    cat.includes("sport") ||
    cat.includes("lauf") ||
    cat.includes("radtour") ||
    cat.includes("fahrrad") ||
    cat.includes("turnier") ||
    cat.includes("yoga")
  ) {
    return "sport";
  }

  if (
    cat.includes("kinder") ||
    cat.includes("familie") ||
    cat.includes("familien") ||
    cat.includes("explorado") ||
    cat.includes("abenteuermuseum") ||
    cat.includes("märchen") ||
    cat.includes("puppentheater") ||
    cat.includes("aktionsnachmittag") ||
    cat.includes("ferienprogramm") ||
    cat.includes("bilderbuch") ||
    cat.includes("vorlese")
  ) {
    return "familie";
  }

  if (
    cat.includes("führung") ||
    cat.includes("fuehrung") ||
    cat.includes("exkursion") ||
    cat.includes("ausflug") ||
    cat.includes("rundgang") ||
    cat.includes("besichtigung") // ✅ NEU
  ) {
    return "fuehrung";
  }

  if (
    cat.includes("workshop") ||
    cat.includes("kurs") ||
    cat.includes("vortrag") ||
    cat.includes("seminar") ||
    cat.includes("yoga") ||        // ✅ NEU
    cat.includes("achtsamkeit")    // ✅ NEU
  ) {
    return "workshop";
  }

  // ✅ NEU: Kino als eigene Kategorie (vor theater)
  if (
    cat.includes("kino") ||
    cat.includes("autokino") ||
    cat.includes("filmvorführung")
  ) {
    return "kino";
  }

  if (
    cat.includes("theater") ||
    cat.includes("comedy") ||
    cat.includes("kabarett") ||
    cat.includes("bühne") ||
    cat.includes("schauspiel") ||
    cat.includes("kleinkunst") ||
    cat.includes("improtheater") ||
    cat.includes("musical") ||
    cat.includes("poetry slam") ||
    cat.includes("stand-up") ||
    cat.includes("lesung") ||
    cat.includes("autorenlesung")
  ) {
    return "theater";
  }

  return "sonstiges";
}

// ✅ Bevorzugte Textvariante finden (mehrere rel/type-Kombinationen möglich)
function pickText(texts, relPreferenceList) {
  for (const rel of relPreferenceList) {
    const found = (texts || []).find(
      (t) => t.rel === rel && t.type === "text/plain" && t.value
    );
    if (found) return found.value;
  }
  return "";
}

async function importNRWDataHubEvents() {
  const licenseKey = "Y2zYmlZt0MibOVvi9VkkMTSmZPnDwjGdc90iAN07";
  const baseParams =
    `experience=open-data-nrw-tourismus&type=Event&licenseKey=${licenseKey}` +
    `&q=area%3A%22Nordrhein-Westfalen%22&template=ET2014A.json&limit=500`;

  const entries = [];
  const seenIds = new Set();
  let offset = 0;
  let overallCount = null;
  let pageCount = 0;
  const MAX_PAGES = 40;

  while (pageCount < MAX_PAGES) {
    const url = `https://meta.et4.de/rest.ashx/search/?${baseParams}&offset=${offset}`;

    let data;

    try {
      const response = await fetch(url);
      data = await response.json();
    } catch (e) {
      console.error("NRW Data Hub: Request fehlgeschlagen", e.message);
      break;
    }

    if (overallCount === null && typeof data.overallcount === "number") {
      overallCount = data.overallcount;
      console.log(`NRW Data Hub: insgesamt ${overallCount} Events verfügbar`);
    }

    const events = data.items || [];

    if (events.length === 0) {
      console.log("NRW Data Hub: Keine weiteren Events, beende Pagination");
      break;
    }

    let newOnThisPage = 0;

    for (const event of events) {
      try {
        const id = event.id || event.global_id;
        if (!id) continue;

        if (seenIds.has(id)) {
          continue;
        }
        seenIds.add(id);
        newOnThisPage++;

        const firstInterval = event.timeIntervals?.[0];
        if (!firstInterval?.start) continue;

        const startDate = admin.firestore.Timestamp.fromDate(
          new Date(firstInterval.start)
        );
        const endDate = firstInterval.end
          ? admin.firestore.Timestamp.fromDate(new Date(firstInterval.end))
          : startDate;

        const latitude = event.geo?.main?.latitude || 0;
        const longitude = event.geo?.main?.longitude || 0;

        let city = event.city || "";
        let zip = event.zip || "";
        let street = event.street || "";

        if (!city && Array.isArray(event.addresses)) {
          const organizerAddr = event.addresses.find(
            (a) => a.rel === "organizer" && a.city
          );
          if (organizerAddr) {
            city = organizerAddr.city || "";
            zip = organizerAddr.zip || "";
            street = organizerAddr.street || "";
          }
        }

        const address =
          [street, [zip, city].filter(Boolean).join(", ")]
            .filter(Boolean)
            .join(", ") ||
          (event.areas && event.areas[0]) ||
          "";

        const description = pickText(event.texts, [
          "open-data-nrw-detail",
          "details",
          "open-data-nrw-teaser",
          "teaser",
        ]);

        const imageObj = (event.media_objects || []).find(
          (m) => m.rel === "default" && m.type && m.type.startsWith("image/")
        );
        const imageUrl = imageObj?.url || "";
        const imageLicense = imageObj?.license || "";

        const copyrightAddr = (event.addresses || []).find(
          (a) => a.rel === "copyright"
        );
        const attribution =
          copyrightAddr?.name || imageObj?.source || "Data Hub NRW";

        const licenseAttr = (event.attributes || []).find(
          (a) => a.key === "license"
        );
        const license = licenseAttr?.value || imageLicense || "";

        // ✅ TIER 3: Service-/Behörden-"Events" gar nicht importieren
        if (isNoiseEvent(`${event.title || ""} ${(event.categories || []).join(" ")}`)) {
          continue;
        }

        const rawCategory = mapNRWCategory(event.categories);
        let category = normalizeCategory(rawCategory);

        // ✅ FALLBACK: Wenn die Quell-Kategorie nichts hergibt, Titel +
        // Beschreibung nach eindeutigen Signalen durchsuchen (fängt z.B.
        // "Kino ...", "Mal-& Zeichentreff", "Familienfrühstück").
        if (category === "sonstiges") {
          const nrwText =
            `${event.title || ""} ${description || ""} ` +
            `${(event.categories || []).join(" ")}`;
          category = normalizeCategory(mapTextToCategory(nrwText));
        }

        entries.push({
          docId: `nrw_${event.id}`,
          data: {
            name: event.title || "",
            address,
            city,
            category,
            subcategory: (event.categories || []).join(", "),
            description,
            latitude,
            longitude,
            startDate,
            endDate,
            flyerUrl: imageUrl,
            images: imageUrl ? [imageUrl] : [],
            ticketUrl: event.web || "",
            venueName: event.name || "",
            isHighlight: false,
            source: "nrw_datahub",
            attribution,
            license,
            importedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        });
      } catch (e) {
        console.error("NRW Data Hub: Event-Fehler", event?.id, e.message);
      }
    }

    pageCount++;
    console.log(
      `NRW Data Hub: Seite ${pageCount} (offset=${offset}) verarbeitet, ${newOnThisPage} neue Events, insgesamt ${entries.length} gesammelt`
    );

    offset += 500;

    if (newOnThisPage === 0) {
      console.log("NRW Data Hub: Keine neuen Events mehr -> Ende erreicht, breche ab");
      break;
    }

    if (overallCount !== null && offset >= overallCount) {
      console.log("NRW Data Hub: overallcount erreicht, beende Pagination");
      break;
    }
  }

  const written = await batchWriteEvents(entries);
  console.log(`NRW Data Hub: ${written} Events importiert über ${pageCount} Seite(n)`);
  return written;
}

//====================================================
// ✅ IMPORT: OS-KALENDER
//====================================================
function mapOSCategory(category) {
  const cat = (category || "").toLowerCase();

  if (cat.includes("kunsthandwerk") || cat.includes("markt")) return "markt";
  if (cat.includes("konzert")) return "konzert";
  if (cat.includes("musik") || cat.includes("chor") || cat.includes("orgel")) return "konzert";
  if (
    cat.includes("familien") ||
    cat.includes("kinder") ||
    cat.includes("explorado") ||
    cat.includes("märchen") ||
    cat.includes("puppentheater")
  ) return "familie";
  if (cat.includes("kulinar")) return "food";
  if (cat.includes("festival") || cat.includes("bierfestival") || cat.includes("open air")) return "festival";
  // ✅ Bonus-Fix: "party"/"bar" -> festival (nachtleben war nie ein gültiger Enum-Wert)
  if (cat.includes("party") || cat.includes("bar")) return "festival";
  // ✅ NEU (Tier 1): Natur & Wandern
  if (
    cat.includes("wanderung") ||
    cat.includes("wandern") ||
    cat.includes("spaziergang") ||
    cat.includes("eifelverein") ||
    cat.includes("naturführung")
  ) return "natur";
  if (cat.includes("führung") || cat.includes("stadtführung") || cat.includes("rundgang")) return "fuehrung";
  if (cat.includes("besichtigung")) return "fuehrung";
  if (cat.includes("workshop") || cat.includes("kurs") || cat.includes("vortrag")) return "workshop";
  if (cat.includes("yoga") || cat.includes("achtsamkeit")) return "workshop";
  // ✅ NEU (Tier 1): Ausstellungs-Signale gehen jetzt nach "kunst" (vorher "theater")
  if (
    cat.includes("ausstellung") ||
    cat.includes("vernissage") ||
    cat.includes("atelier") ||
    cat.includes("malerei") ||
    cat.includes("galerie") ||
    cat.includes("kunst")
  ) return "kunst";
  // ✅ NEU: Kino als eigene Kategorie (vor theater)
  if (cat.includes("kino") || cat.includes("autokino")) return "kino";
  if (
    cat.includes("theater") ||
    cat.includes("comedy") ||
    cat.includes("kabarett") ||
    cat.includes("kleinkunst") ||
    cat.includes("lesung") ||
    cat.includes("leseabend")
  ) return "theater";
  if (cat.includes("fahrrad") || cat.includes("ausflugsfahrt") || cat.includes("sport")) return "sport";

  return "sonstiges";
}

async function importOSKalenderEvents() {
  const baseUrl =
    "https://www.os-kalender.de/alle-events-in-der-uebersicht/All/layout:card/sort:chronological/type:Event/-category:(Ausstellung%20OR%20Dauerausstellung%20OR%20Sonderausstellung%20OR%20Wanderausstellung)/limit:1000/";
  let url = baseUrl;
  const entries = [];
  const seenIds = new Set();
  let pageCount = 0;
  const MAX_PAGES = 200;

  function parseGermanDate(dateStr, timeStr) {
    const m = dateStr.match(/(\d{1,2})\.(\d{1,2})\.(\d{4})/);
    if (!m) return null;

    const [, day, month, year] = m;
    const monthNum = parseInt(month, 10);
    const offset = monthNum >= 4 && monthNum <= 10 ? "+02:00" : "+01:00";
    const time = /^\d{1,2}:\d{2}$/.test(timeStr || "") ? timeStr : "00:00";

    const iso = `${year}-${month.padStart(2, "0")}-${day.padStart(2, "0")}T${time}:00${offset}`;
    const dt = new Date(iso);
    return isNaN(dt.getTime()) ? null : dt;
  }

  const CARD_START_REGEX = /<div class="teaser-card result-item[^"]*"/g;

  while (url && pageCount < MAX_PAGES) {
    let html;

    try {
      const res = await fetch(url);
      html = await res.text();
    } catch (e) {
      console.error("OSKalender: Fetch fehlgeschlagen für", url, e.message);
      break;
    }

    const startPositions = [...html.matchAll(CARD_START_REGEX)].map((m) => m.index);

    if (startPositions.length === 0) {
      console.log("OSKalender: Keine Karten mehr auf dieser Seite, beende Pagination");
      break;
    }

    const cards = startPositions.map((start, i) => {
      const end = i + 1 < startPositions.length ? startPositions[i + 1] : html.length;
      return html.slice(start, end);
    });

    let newIdsOnThisPage = 0;
    let parseFailuresOnThisPage = 0;

    for (const card of cards) {
      try {
        const idMatch = card.match(/data-globalid="e_(\d+)"/);

        if (!idMatch) {
          parseFailuresOnThisPage++;
          continue;
        }

        const osId = idMatch[1];

        if (seenIds.has(osId)) {
          continue;
        }
        seenIds.add(osId);
        newIdsOnThisPage++;

        const linkMatch = card.match(
          /<a href="(https:\/\/www\.os-kalender\.de\/event\/[a-z0-9\-]+)"/
        );
        const detailUrl = linkMatch ? linkMatch[1] : "";

        const titleMatch = card.match(/<span class="teaser-card__header">([^<]*)<\/span>/);
        const title = titleMatch ? titleMatch[1].trim() : "";

        const dateMatch = card.match(/<span class="teaser-card__subheader">([^<]*)<\/span>/);
        const dateRaw = dateMatch ? dateMatch[1].trim() : "";

        const allTexts = [
          ...card.matchAll(/<div class="teaser-line__text">([^<]*)<\/div>/g),
        ].map((m) => m[1].trim());

        const time = allTexts[0] || "";
        const rawCategory = allTexts.length >= 3 ? allTexts[1] : "";
        const address = allTexts.length > 0 ? allTexts[allTexts.length - 1] : "";

        const cityMatch = address.match(/\d{5}\s+([^,(]+)/);
        const city = cityMatch ? cityMatch[1].trim() : "";

        const dateParts = dateRaw.split(" - ").map((d) => d.trim());
        const startDateObj = parseGermanDate(dateParts[0], time);
        const endDateObj = dateParts[1]
          ? parseGermanDate(dateParts[1], time)
          : startDateObj;

        if (!startDateObj) {
          console.log(`OSKalender: Kein gültiges Datum für ${osId} ("${dateRaw}"), überspringe`);
          continue;
        }

        // ✅ ANGEPASST: Titel UND Kategorie-Tag zusammen durchsuchen,
        // statt nur den isolierten Kategorie-Tag der Karte (behebt den
        // Bug, dass Titel-Keywords wie "Führung" nie erkannt wurden,
        // z.B. bei "Führung durch das Dinoversum").
        const categorySearchText = `${title} ${rawCategory}`.toLowerCase();

        // ✅ TIER 3: Service-/Behörden-"Events" gar nicht importieren
        if (isNoiseEvent(categorySearchText)) {
          continue;
        }

        const category = (() => {
          const c = normalizeCategory(mapOSCategory(categorySearchText));
          return c === "sonstiges"
              ? normalizeCategory(mapTextToCategory(categorySearchText))
              : c;
        })();

        entries.push({
          docId: `os_${osId}`,
          data: {
            osId,
            source: "oskalender",
            name: title,
            category,
            subcategory: rawCategory,
            address,
            city,
            startDate: admin.firestore.Timestamp.fromDate(startDateObj),
            endDate: admin.firestore.Timestamp.fromDate(endDateObj || startDateObj),
            detailUrl,
            importedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        });
      } catch (e) {
        console.error("OSKalender: Karten-Fehler", e.message);
      }
    }

    pageCount++;
    console.log(
      `OSKalender: Seite ${pageCount} verarbeitet, ${newIdsOnThisPage} neue Events, ${parseFailuresOnThisPage} Parse-Fehler, insgesamt ${entries.length} gesammelt`
    );

    if (newIdsOnThisPage === 0 && parseFailuresOnThisPage === 0 && cards.length > 0) {
      console.log("OSKalender: Nur bereits bekannte Events auf dieser Seite -> echtes Ende erreicht, breche ab");
      break;
    }

    const nextMatch = html.match(/<link rel="next" href="([^"]+)"/);
    url = nextMatch ? nextMatch[1].replace(/&amp;/g, "&") : null;
  }

  const written = await batchWriteEvents(entries);

  try {
    const existingSnapshot = await db
      .collection("events")
      .where("source", "==", "oskalender")
      .get();

    const staleDocs = existingSnapshot.docs.filter((doc) => {
      const osId = doc.data().osId;
      return osId && !seenIds.has(osId);
    });

    if (staleDocs.length > 0) {
      const CHUNK_SIZE = 450;

      for (let i = 0; i < staleDocs.length; i += CHUNK_SIZE) {
        const chunk = staleDocs.slice(i, i + CHUNK_SIZE);
        const deleteBatch = db.batch();

        for (const doc of chunk) {
          deleteBatch.delete(doc.ref);
        }

        await deleteBatch.commit();
      }

      console.log(`OSKalender: ${staleDocs.length} veraltete Events entfernt (nicht mehr in der Quelle vorhanden)`);
    } else {
      console.log("OSKalender: Keine veralteten Events zu entfernen");
    }
  } catch (e) {
    console.error("OSKalender: Fehler beim Entfernen veralteter Events:", e.message);
  }

  console.log(`OSKalender: ${written} Events importiert über ${pageCount} Seite(n)`);
  return written;
}

//====================================================
// ✅ REPORT: ALLE EVENTS IN "SONSTIGES"
//====================================================
exports.listSonstigesEvents = onRequest(
  { timeoutSeconds: 60 },
  async (req, res) => {
    try {
      const snapshot = await db
        .collection("events")
        .where("category", "==", "sonstiges")
        .get();

      const items = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          name: data.name || "(kein Name)",
          source: data.source || "?",
          city: data.city || "",
        };
      });

      // Alphabetisch sortieren, damit Wiederholungen/Muster leichter auffallen
      items.sort((a, b) => a.name.localeCompare(b.name, "de"));

      const lines = items.map(
        (i) => `${i.name}  |  Quelle: ${i.source}  |  Ort: ${i.city}`
      );

      const output =
        `Insgesamt ${items.length} Events in "sonstiges":\n\n` +
        lines.join("\n");

      res.set("Content-Type", "text/plain; charset=utf-8");
      res.send(output);
    } catch (error) {
      console.error(error);
      res.status(500).send(error.toString());
    }
  }
);

//====================================================
// ✅ CLEANUP: BESTAND IN "SONSTIGES" NACHTRÄGLICH BEREINIGEN
//====================================================
// Läuft einmalig über alle bereits gespeicherten "sonstiges"-Docs und:
//  - LÖSCHT Service-/Behörden-Noise (isNoiseEvent) – der Import-Skip
//    verhindert nur NEUE Noise-Docs, entfernt aber keine bestehenden.
//  - RE-KATEGORISIERT Events, deren Titel ein eindeutiges Signal trägt
//    (mapTextToCategory), z.B. "Kino ...", "Familienfrühstück".
// Idempotent: mehrfaches Aufrufen ist unschädlich.
exports.recategorizeSonstiges = onRequest(
  { timeoutSeconds: 300, memory: "512MiB" },
  async (req, res) => {
    try {
      const snapshot = await db
        .collection("events")
        .where("category", "==", "sonstiges")
        .get();

      let deleted = 0;
      let updated = 0;
      let kept = 0;

      let batch = db.batch();
      let ops = 0;
      const flush = async () => {
        if (ops > 0) {
          await batch.commit();
          batch = db.batch();
          ops = 0;
        }
      };

      for (const doc of snapshot.docs) {
        const name = doc.data().name || "";

        if (isNoiseEvent(name)) {
          batch.delete(doc.ref);
          deleted++;
          ops++;
        } else {
          const cat = mapTextToCategory(name);
          if (cat !== "sonstiges") {
            batch.update(doc.ref, { category: cat });
            updated++;
            ops++;
          } else {
            kept++;
          }
        }

        if (ops >= 400) await flush();
      }

      await flush();

      const summary =
        `Bestand "sonstiges" bereinigt (${snapshot.size} geprüft):\n` +
        `- ${updated} neu kategorisiert\n` +
        `- ${deleted} Noise gelöscht\n` +
        `- ${kept} bleiben in "sonstiges"`;

      console.log(summary);
      res.set("Content-Type", "text/plain; charset=utf-8");
      res.send(summary);
    } catch (error) {
      console.error(error);
      res.status(500).send(error.toString());
    }
  }
);
//====================================================
// ✅ HTTP TRIGGER
//====================================================
exports.syncOSKalender = onRequest(
  { timeoutSeconds: 900, memory: "1GiB" },
  async (req, res) => {
    try {
      const count = await importOSKalenderEvents();
      res.send(`OSKalender: ${count}`);
    } catch (error) {
      console.error(error);
      res.status(500).send(error.toString());
    }
  }
);

exports.syncNRWDataHub = onRequest(
  { timeoutSeconds: 900, memory: "1GiB" },
  async (req, res) => {
    try {
      const count = await importNRWDataHubEvents();
      res.send(`NRW Data Hub: ${count}`);
    } catch (error) {
      console.error(error);
      res.status(500).send(error.toString());
    }
  }
);

exports.syncTicketmaster = onRequest(
  { timeoutSeconds: 540, memory: "1GiB" },
  async (req, res) => {
    try {
      const tm = await importTicketmasterEvents();
      const et4 = await importMuehlenkreisEvents();
      res.send(`Ticketmaster: ${tm} | ET4: ${et4}`);
    } catch (error) {
      console.error(error);
      res.status(500).send(error.toString());
    }
  }
);

//====================================================
// ✅ SCHEDULED TRIGGER
//====================================================
exports.syncTicketmasterDaily = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "Europe/Berlin",
    timeoutSeconds: 540,
  },
  async () => {
    try {
      const tm = await importTicketmasterEvents();
      const et4 = await importMuehlenkreisEvents();
      console.log(`Ticketmaster: ${tm} | ET4: ${et4}`);
    } catch (error) {
      console.error(error);
    }
  }
);

exports.syncNRWDataHubDaily = onSchedule(
  {
    schedule: "0 4 * * *",
    timeZone: "Europe/Berlin",
    timeoutSeconds: 900,
  },
  async () => {
    try {
      const count = await importNRWDataHubEvents();
      console.log(`NRW Data Hub: ${count}`);
    } catch (error) {
      console.error(error);
    }
  }
);