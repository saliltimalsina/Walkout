"use client";
import { useEffect, useState } from "react";
import {
  GoogleAuthProvider,
  signInWithPopup,
  signOut,
  onAuthStateChanged,
  type User,
} from "firebase/auth";
import {
  collection,
  doc,
  onSnapshot,
  setDoc,
  serverTimestamp,
} from "firebase/firestore";
import { auth, db } from "../lib/firebase";

const RED = "#E50914";
const CARD = "#161618";
const LINE = "#2A2A2E";

type Row = Record<string, any> & { id: string };

export default function Page() {
  const [user, setUser] = useState<User | null>(null);
  const [isAdmin, setAdmin] = useState(false);
  const [tab, setTab] = useState<"monitor" | "fighters" | "events" | "media">("monitor");

  useEffect(() => {
    return onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (u) {
        const t = await u.getIdTokenResult(true);
        setAdmin(t.claims.admin === true);
      } else setAdmin(false);
    });
  }, []);

  if (!user)
    return (
      <Center>
        <h1>Walkout Dashboard</h1>
        <button style={btn} onClick={() => signInWithPopup(auth, new GoogleAuthProvider())}>
          Sign in with Google
        </button>
      </Center>
    );

  if (!isAdmin)
    return (
      <Center>
        <p>
          {user.email} is not an admin. Grant the <code>admin</code> claim (see SETUP.md), then
          sign out and back in.
        </p>
        <button style={btn} onClick={() => signOut(auth)}>Sign out</button>
      </Center>
    );

  return (
    <div style={{ maxWidth: 1000, margin: "0 auto", padding: 20 }}>
      <header style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
        <h1 style={{ margin: 0, fontSize: 22 }}>
          WALK<span style={{ color: RED }}>OUT</span> · Data
        </h1>
        <div style={{ flex: 1 }} />
        <PublishButton email={user.email!} />
        <button style={btnGhost} onClick={() => signOut(auth)}>Sign out</button>
      </header>

      <nav style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        {(["monitor", "fighters", "events", "media"] as const).map((t) => (
          <button key={t} onClick={() => setTab(t)} style={tab === t ? tabOn : tabOff}>
            {t.toUpperCase()}
          </button>
        ))}
      </nav>

      {tab === "monitor" && <Monitor />}
      {tab === "fighters" && <Editor coll="fighters" title="Fighters" />}
      {tab === "events" && <Editor coll="events" title="Events" />}
      {tab === "media" && <Media />}
    </div>
  );
}

function PublishButton({ email }: { email: string }) {
  const [busy, setBusy] = useState(false);
  return (
    <button
      style={{ ...btn, opacity: busy ? 0.6 : 1 }}
      disabled={busy}
      onClick={async () => {
        setBusy(true);
        await setDoc(doc(db, "meta", "publish"), { at: serverTimestamp(), by: email }, { merge: true });
        setTimeout(() => setBusy(false), 1200);
      }}
    >
      {busy ? "Pushed ✓" : "Publish → phones"}
    </button>
  );
}

function Monitor() {
  const [meta, setMeta] = useState<any>(null);
  const [counts, setCounts] = useState<Record<string, number>>({});
  useEffect(() => {
    const unsubs = [
      onSnapshot(doc(db, "meta", "ingest"), (d) => setMeta(d.data())),
      ...["fighters", "events", "rankings", "media"].map((c) =>
        onSnapshot(collection(db, c), (s) => setCounts((p) => ({ ...p, [c]: s.size })))
      ),
    ];
    return () => unsubs.forEach((u) => u());
  }, []);
  const errs: string[] = meta?.errors ?? [];
  return (
    <div style={cardStyle}>
      <Grid>
        <Stat label="Fighters" v={counts.fighters ?? "—"} />
        <Stat label="Events" v={counts.events ?? "—"} />
        <Stat label="Rankings" v={counts.rankings ?? "—"} />
        <Stat label="Media (deduped)" v={counts.media ?? "—"} />
      </Grid>
      <p style={{ color: "#A6A6AD", marginTop: 16 }}>
        Last ingest: {meta?.lastRunAt?.toDate ? meta.lastRunAt.toDate().toLocaleString() : "—"} ·
        source {meta?.source ?? "—"} · tick {meta?.tick ?? "—"}
      </p>
      <h3 style={{ color: errs.length ? RED : "#22C55E" }}>
        {errs.length ? `${errs.length} scrape error(s)` : "Healthy"}
      </h3>
      {errs.map((e, i) => (
        <div key={i} style={{ color: RED, fontFamily: "monospace", fontSize: 13 }}>{e}</div>
      ))}
    </div>
  );
}

function Editor({ coll, title }: { coll: string; title: string }) {
  const [rows, setRows] = useState<Row[]>([]);
  const [q, setQ] = useState("");
  const [sel, setSel] = useState<Row | null>(null);
  useEffect(() => {
    return onSnapshot(collection(db, coll), (s) =>
      setRows(s.docs.map((d) => ({ id: d.id, ...d.data() } as Row)))
    );
  }, [coll]);
  const shown = rows
    .filter((r) => JSON.stringify(r).toLowerCase().includes(q.toLowerCase()))
    .slice(0, 200);
  return (
    <div style={{ display: "flex", gap: 16 }}>
      <div style={{ flex: 1 }}>
        <input placeholder={`Search ${title}`} value={q} onChange={(e) => setQ(e.target.value)} style={input} />
        <div style={{ ...cardStyle, maxHeight: 520, overflow: "auto", padding: 0 }}>
          {shown.map((r) => (
            <div
              key={r.id}
              onClick={() => setSel(r)}
              style={{ padding: "10px 12px", borderBottom: `1px solid ${LINE}`, cursor: "pointer", background: sel?.id === r.id ? "#202024" : "transparent" }}
            >
              {r.name ?? r.subtitle ?? r.id}
              <span style={{ color: "#6E6E76", marginLeft: 8, fontSize: 12 }}>{r.id}</span>
            </div>
          ))}
        </div>
      </div>
      <div style={{ flex: 1 }}>{sel ? <DocForm coll={coll} row={sel} /> : <div style={cardStyle}>Pick a row to edit.</div>}</div>
    </div>
  );
}

function DocForm({ coll, row }: { coll: string; row: Row }) {
  const [draft, setDraft] = useState<Row>(row);
  const [locked, setLocked] = useState<string[]>(row.locked ?? []);
  const [saved, setSaved] = useState(false);
  useEffect(() => {
    setDraft(row);
    setLocked(row.locked ?? []);
  }, [row]);
  const scalars = Object.entries(draft).filter(
    ([k, v]) => k !== "locked" && (typeof v === "string" || typeof v === "number" || typeof v === "boolean")
  );
  return (
    <div style={cardStyle}>
      <h3 style={{ marginTop: 0 }}>{draft.id}</h3>
      {scalars.map(([k, v]) => (
        <div key={k} style={{ marginBottom: 10 }}>
          <label style={{ display: "flex", gap: 8, alignItems: "center", fontSize: 12, color: "#A6A6AD" }}>
            <input
              type="checkbox"
              checked={locked.includes(k)}
              onChange={(e) => setLocked((L) => (e.target.checked ? [...L, k] : L.filter((x) => x !== k)))}
            />
            {k} {locked.includes(k) && <span style={{ color: RED }}>lock</span>}
          </label>
          <input
            style={input}
            value={String(v)}
            onChange={(e) => setDraft((d) => ({ ...d, [k]: typeof v === "number" ? Number(e.target.value) : e.target.value }))}
          />
        </div>
      ))}
      <button
        style={btn}
        onClick={async () => {
          await setDoc(doc(db, coll, draft.id), { ...draft, locked }, { merge: true });
          setSaved(true);
          setTimeout(() => setSaved(false), 1200);
        }}
      >
        {saved ? "Saved ✓" : "Save"}
      </button>
      <p style={{ color: "#6E6E76", fontSize: 12 }}>
        Locked fields are never overwritten by the scraper.
      </p>
    </div>
  );
}

function Media() {
  const [rows, setRows] = useState<Row[]>([]);
  useEffect(() => {
    return onSnapshot(collection(db, "media"), (s) =>
      setRows(s.docs.map((d) => ({ id: d.id, ...d.data() } as Row)))
    );
  }, []);
  return (
    <div style={{ ...cardStyle, display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(120px,1fr))", gap: 10 }}>
      {rows.map((r) => (
        // eslint-disable-next-line @next/next/no-img-element
        <img key={r.id} src={r.url} alt={r.kind} title={`${r.kind} · ${r.id.slice(0, 8)}`} style={{ width: "100%", borderRadius: 8, aspectRatio: "1", objectFit: "cover", background: "#000" }} />
      ))}
    </div>
  );
}

// ── bits ──
const Center = ({ children }: { children: React.ReactNode }) => (
  <div style={{ display: "grid", placeItems: "center", height: "100vh", gap: 16, textAlign: "center", padding: 20 }}>{children}</div>
);
const Grid = ({ children }: { children: React.ReactNode }) => (
  <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(150px,1fr))", gap: 12 }}>{children}</div>
);
const Stat = ({ label, v }: { label: string; v: any }) => (
  <div style={{ background: "#0B0B0D", border: `1px solid ${LINE}`, borderRadius: 10, padding: 14 }}>
    <div style={{ fontSize: 28, fontWeight: 800 }}>{v}</div>
    <div style={{ color: "#A6A6AD", fontSize: 12 }}>{label}</div>
  </div>
);

const cardStyle: React.CSSProperties = { background: CARD, border: `1px solid ${LINE}`, borderRadius: 12, padding: 16 };
const btn: React.CSSProperties = { background: RED, color: "#fff", border: 0, borderRadius: 8, padding: "10px 16px", fontWeight: 700, cursor: "pointer" };
const btnGhost: React.CSSProperties = { background: "transparent", color: "#A6A6AD", border: `1px solid ${LINE}`, borderRadius: 8, padding: "10px 16px", cursor: "pointer" };
const tabOn: React.CSSProperties = { ...btnGhost, color: "#fff", borderColor: RED };
const tabOff: React.CSSProperties = btnGhost;
const input: React.CSSProperties = { width: "100%", background: "#0B0B0D", color: "#fff", border: `1px solid ${LINE}`, borderRadius: 8, padding: 10, marginBottom: 8, boxSizing: "border-box" };
