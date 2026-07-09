import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import { getMessaging } from "firebase-admin/messaging";

const TOPIC = "walkout_data";

/**
 * Fires once whenever ingest stamps `meta/ingest` or the dashboard writes
 * `meta/publish`. Sends a silent data message to every device on the topic;
 * the app wakes a background isolate and re-renders the home-screen widgets.
 */
export const onDataChanged = onDocumentWritten("meta/{docId}", async (event) => {
  try {
    await getMessaging().send({
      topic: TOPIC,
      data: { type: "data_changed", at: String(Date.now()) },
      android: { priority: "high" },
      apns: { headers: { "apns-priority": "5" }, payload: { aps: { contentAvailable: true } } },
    });
    logger.info(`data_changed pushed (${event.params.docId})`);
  } catch (e: any) {
    logger.error(`push failed: ${e?.message ?? e}`);
  }
});
