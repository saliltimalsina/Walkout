import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { fetchFighters, fetchEvents, fetchRankings } from "./sources";
import { mirrorImage } from "./media";

/**
 * Runs every minute. Events refresh every run (so a live card updates within
 * ~1 min — sub-minute would need a self-looping Cloud Run job). Fighters and
 * rankings refresh ~every 30 min, since they rarely change. Manual dashboard
 * edits are protected: any field listed in a doc's `locked[]` is never
 * overwritten by a scrape.
 */
export const scheduledIngest = onSchedule(
  { schedule: "every 1 minutes", timeoutSeconds: 300, memory: "512MiB" },
  async () => {
    const db = getFirestore();
    const metaRef = db.collection("meta").doc("ingest");
    const meta = (await metaRef.get()).data() || {};
    const tick = ((meta.tick as number) || 0) + 1;
    const errors: string[] = [];

    async function mergeLocked(coll: string, id: string, incoming: any, imageFields: Record<string, "fighter" | "poster">) {
      const ref = db.collection(coll).doc(id);
      const existing = (await ref.get()).data() || {};
      const locked: string[] = existing.locked || [];
      const merged: any = { ...incoming };
      // Mirror any external image URLs into our deduped Storage bucket.
      for (const [field, kind] of Object.entries(imageFields)) {
        const v = merged[field];
        if (typeof v === "string" && v.startsWith("http") && !v.includes("storage.googleapis.com")) {
          merged[field] = (await mirrorImage(v, kind)) || existing[field] || "";
        }
      }
      for (const f of locked) if (existing[f] !== undefined) merged[f] = existing[f];
      merged.locked = locked;
      merged.updatedAt = FieldValue.serverTimestamp();
      await ref.set(merged, { merge: true });
    }

    // Events — every run.
    try {
      const events = await fetchEvents();
      if (events) {
        for (const e of events) {
          await mergeLocked("events", e.id, e, { heroImage: "poster" });
        }
        logger.info(`ingest: events ${events.length}`);
      } else {
        errors.push("events: no source");
      }
    } catch (e: any) {
      errors.push(`events: ${e?.message ?? e}`);
    }

    // Fighters + rankings — every ~30 min.
    if (tick % 30 === 1) {
      try {
        const fighters = await fetchFighters();
        if (fighters) {
          for (const f of fighters) {
            await mergeLocked("fighters", f.id, f, { imageUrl: "fighter" });
          }
          logger.info(`ingest: fighters ${fighters.length}`);
        }
      } catch (e: any) {
        errors.push(`fighters: ${e?.message ?? e}`);
      }
      try {
        const rankings = await fetchRankings();
        if (rankings) {
          for (const r of rankings) {
            await db.collection("rankings").doc(r.weightClass).set(
              { ...r, updatedAt: FieldValue.serverTimestamp() },
              { merge: true }
            );
          }
          logger.info(`ingest: rankings ${rankings.length}`);
        }
      } catch (e: any) {
        errors.push(`rankings: ${e?.message ?? e}`);
      }
    }

    // Stamping meta triggers the publish→FCM fan-out exactly once per run.
    await metaRef.set(
      { lastRunAt: FieldValue.serverTimestamp(), tick, source: "ingest", errors },
      { merge: true }
    );
  }
);
