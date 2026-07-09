import { initializeApp } from "firebase-admin/app";

initializeApp();

export { scheduledIngest } from "./ingest";
export { onDataChanged } from "./publish";
