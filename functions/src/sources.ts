// Data acquisition layer. There are two interchangeable sources behind one
// contract — both must return docs shaped exactly like assets/data/*.json:
//
//   1. SCRAPER_URL  (recommended, reliable): your existing Scrapling scraper,
//      exposed as HTTP or a GitHub Action that publishes JSON. The function
//      pulls already-normalized JSON. Set env SCRAPER_URL to its base.
//        GET {SCRAPER_URL}/fighters.json  -> Fighter[]
//        GET {SCRAPER_URL}/events.json    -> Event[]
//        GET {SCRAPER_URL}/rankings.json  -> Ranking[]
//
//   2. UFC endpoints (optional, fragile): the JSON behind ufc.com pages. Plug
//      real URLs into `fetchUfc*` and normalize to the schema. Left as TODO
//      because these are unofficial and change without notice — keep the
//      scraper as the source of truth and this as an accelerator.
//
// Either way the output is the same shape, so ingest.ts is source-agnostic.

export interface Normalized {
  fighters: any[];
  events: any[];
  rankings: any[];
}

const SCRAPER_URL = process.env.SCRAPER_URL;

async function getJson<T>(url: string): Promise<T | null> {
  try {
    const res = await fetch(url, { headers: { accept: "application/json" } });
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null;
  }
}

/** Pull one collection from the Scrapling service. */
async function fromScraper(name: string): Promise<any[] | null> {
  if (!SCRAPER_URL) return null;
  return getJson<any[]>(`${SCRAPER_URL.replace(/\/$/, "")}/${name}.json`);
}

// ── Direct UFC endpoints (TODO: confirm + fill in) ──────────────────────────
// Example shape only. ufc.com serves athlete/event/ranking JSON behind its
// pages; discover the real endpoints (devtools → Network → XHR) and map fields
// to the schema here. Return null to defer to the scraper.
async function fetchUfcFighters(): Promise<any[] | null> {
  return null;
}
async function fetchUfcEvents(): Promise<any[] | null> {
  return null;
}
async function fetchUfcRankings(): Promise<any[] | null> {
  return null;
}

export async function fetchFighters(): Promise<any[] | null> {
  return (await fetchUfcFighters()) ?? (await fromScraper("fighters"));
}
export async function fetchEvents(): Promise<any[] | null> {
  return (await fetchUfcEvents()) ?? (await fromScraper("events"));
}
export async function fetchRankings(): Promise<any[] | null> {
  return (await fetchUfcRankings()) ?? (await fromScraper("rankings"));
}
