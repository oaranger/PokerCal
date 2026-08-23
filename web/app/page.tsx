"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { calculateSettlement, Player } from "./settlement";

const STORAGE_KEY = "pokercal.players.v1";
const makeId = () => globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random()}`;
const numberFromForm = (form: FormData, key: string) => {
  const value = Number(form.get(key));
  return Number.isFinite(value) ? Math.max(0, Math.trunc(value)) : 0;
};
const valueClass = (value: number) => value > 0 ? "positive" : value < 0 ? "negative" : "neutral";

export default function Home() {
  const [players, setPlayers] = useState<Player[]>([]);
  const [ready, setReady] = useState(false);
  const [adding, setAdding] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  useEffect(() => {
    let savedPlayers: Player[] = [];
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) savedPlayers = JSON.parse(saved);
    } catch { localStorage.removeItem(STORAGE_KEY); }
    queueMicrotask(() => { setPlayers(savedPlayers); setReady(true); });
  }, []);
  useEffect(() => { if (ready) localStorage.setItem(STORAGE_KEY, JSON.stringify(players)); }, [players, ready]);

  const settlement = useMemo(() => calculateSettlement(players), [players]);
  const editing = players.find((player) => player.id === editingId) ?? null;
  const updatePlayer = (id: string, update: (player: Player) => Player) =>
    setPlayers((current) => current.map((player) => player.id === id ? update(player) : player));

  function addPlayer(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const name = String(data.get("name") ?? "").trim();
    if (!name) return;
    const buyIn = numberFromForm(data, "buyIn");
    setPlayers((current) => [...current, {
      id: makeId(), name, buyIns: buyIn > 0 ? [{ id: makeId(), amount: buyIn }] : [],
      checkout: numberFromForm(data, "checkout"), spent: numberFromForm(data, "spent"),
    }]);
    setAdding(false);
  }

  function resetGame() {
    if (!players.length || window.confirm("Reset every player's buy-ins, cash out, and food expense?")) {
      setPlayers((current) => current.map((player) => ({ ...player, buyIns: [], checkout: 0, spent: 0 })));
    }
  }

  return (
    <main>
      <header className="topbar">
        <a className="brand" href="#top" aria-label="PokerCal home"><span className="brand-mark">♠</span><span>PokerCal</span></a>
        <span className="date-chip">{new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", year: "numeric" }).format(new Date())}</span>
      </header>

      <section className="hero" id="top">
        <div><p className="eyebrow">SETTLE THE TABLE</p><h1>Everyone leaves square.</h1><p className="intro">Track buy-ins, cash-outs, and shared food. PokerCal balances the final payouts and rounds them to friendly increments of five.</p></div>
        <div className="hero-actions"><button className="button secondary" onClick={resetGame}>Reset amounts</button><button className="button primary" onClick={() => setAdding(true)}>+ Add player</button></div>
      </section>

      <section className="summary" aria-label="Game summary">
        <div><span>Players</span><strong>{players.length}</strong></div><div><span>Total in</span><strong>{settlement.totalIn}</strong></div><div><span>Total out</span><strong>{settlement.totalOut}</strong></div><div><span>Food</span><strong>{settlement.groupSpent}</strong></div>
        <div className={settlement.mismatched ? "attention" : "balanced"}><span>{settlement.mismatched ? settlement.balanceLabel : "Status"}</span><strong>{settlement.mismatched ? settlement.balanceAmount : "Balanced"}</strong></div>
      </section>

      <section className={`ledger ${settlement.mismatched ? "is-mismatched" : ""}`}>
        <div className="ledger-heading"><div><p className="eyebrow">LIVE LEDGER</p><h2>Table settlement</h2></div><div className="legend"><span className="dot win" /> Win {settlement.groupWin} <span className="dot loss" /> Lose {settlement.groupLose}</div></div>
        {players.length === 0 ? <div className="empty-state"><span className="empty-cards">♣ ♥</span><h3>Your table is ready</h3><p>Add the first player to begin tracking tonight&apos;s game.</p><button className="button primary" onClick={() => setAdding(true)}>+ Add first player</button></div> : (
          <><div className="table-scroll"><table>
            <thead><tr><th>Player</th><th>In</th><th>Out</th><th>Diff</th><th>Adju</th><th>Final</th><th><span className="sr-only">Actions</span></th></tr></thead>
            <tbody>{players.map((player) => {
              const totalBuyIn = player.buyIns.reduce((sum, entry) => sum + entry.amount, 0);
              const current = player.checkout - totalBuyIn;
              const final = settlement.finalValues[player.id] ?? 0;
              return <tr key={player.id}>
                <td><button className="player-name" onClick={() => setEditingId(player.id)}>{player.name}</button>{player.spent > 0 && <small>Food {player.spent}</small>}</td><td>{totalBuyIn}</td><td>{player.checkout}</td>
                <td className={settlement.showDiff ? valueClass(current) : "muted"}>{settlement.showDiff ? current : "_"}</td>
                <td className={settlement.mismatched ? valueClass(settlement.adjustments[player.id]) : "muted"}>{settlement.mismatched ? settlement.adjustments[player.id] : "_"}</td>
                <td><span className={`final-pill ${valueClass(final)}`}>{final > 0 ? "+" : ""}{final}</span></td><td><button className="edit-button" onClick={() => setEditingId(player.id)} aria-label={`Edit ${player.name}`}>Edit</button></td>
              </tr>;
            })}</tbody>
            <tfoot><tr><td>Total</td><td>{settlement.totalIn}</td><td>{settlement.totalOut}</td><td>{settlement.showDiff ? players.reduce((sum, p) => sum + p.checkout - p.buyIns.reduce((t, b) => t + b.amount, 0), 0) : "_"}</td><td>{settlement.mismatched ? Object.values(settlement.adjustments).reduce((a, b) => a + b, 0) : "_"}</td><td><span className="zero-sum">0</span></td><td /></tr></tfoot>
          </table></div>
          <div className="mobile-settlements">
            {players.map((player) => {
              const totalBuyIn = player.buyIns.reduce((sum, entry) => sum + entry.amount, 0);
              const current = player.checkout - totalBuyIn;
              const adjustment = settlement.adjustments[player.id] ?? 0;
              const final = settlement.finalValues[player.id] ?? 0;
              return <article className="settlement-card" key={player.id}>
                <button className="settlement-card-heading" onClick={() => setEditingId(player.id)}>
                  <span><strong>{player.name}</strong>{player.spent > 0 && <small>Food / drink {player.spent}</small>}</span>
                  <span className={`final-pill ${valueClass(final)}`}><small>FINAL</small>{final > 0 ? "+" : ""}{final}</span>
                </button>
                <div className="settlement-values">
                  <div><span>In</span><strong>{totalBuyIn}</strong></div>
                  <div><span>Out</span><strong>{player.checkout}</strong></div>
                  <div><span>Diff</span><strong className={settlement.showDiff ? valueClass(current) : "muted"}>{settlement.showDiff ? current : "_"}</strong></div>
                  <div><span>Adju</span><strong className={settlement.mismatched ? valueClass(adjustment) : "muted"}>{settlement.mismatched ? adjustment : "_"}</strong></div>
                </div>
              </article>;
            })}
            <div className="mobile-zero-sum"><span>Final total</span><strong>0</strong></div>
            <p className="mobile-edit-hint">Tap a player to edit their amounts.</p>
          </div></>
        )}
      </section>

      <footer><p>Saved automatically on this device.</p>{players.length > 0 && <button className="text-button danger" onClick={() => { if (window.confirm("Remove every player and start a new table?")) setPlayers([]); }}>Start a new table</button>}</footer>

      {adding && <div className="modal-backdrop"><form className="modal" onSubmit={addPlayer}>
        <div className="modal-header"><div><p className="eyebrow">NEW SEAT</p><h2>Add a player</h2></div><button type="button" className="close" onClick={() => setAdding(false)} aria-label="Close">×</button></div>
        <label>Player name<input name="name" required placeholder="e.g. Alex" /></label><div className="form-grid"><label>Initial buy-in<input name="buyIn" type="number" inputMode="numeric" min="0" defaultValue="50" /></label><label>Cash out<input name="checkout" type="number" inputMode="numeric" min="0" defaultValue="0" /></label></div><label>Food / drink paid<input name="spent" type="number" inputMode="numeric" min="0" defaultValue="0" /></label><button className="button primary wide" type="submit">Add to table</button>
      </form></div>}

      {editing && <div className="modal-backdrop"><div className="modal editor">
        <div className="modal-header"><div><p className="eyebrow">PLAYER DETAILS</p><h2>{editing.name}</h2></div><button className="close" onClick={() => setEditingId(null)} aria-label="Close">×</button></div>
        <div className="player-totals"><div><span>Total in</span><strong>{editing.buyIns.reduce((s, b) => s + b.amount, 0)}</strong></div><div><span>Current diff</span><strong className={valueClass(editing.checkout - editing.buyIns.reduce((s, b) => s + b.amount, 0))}>{editing.checkout - editing.buyIns.reduce((s, b) => s + b.amount, 0)}</strong></div></div>
        <form className="quick-form" onSubmit={(event) => { event.preventDefault(); const amount = numberFromForm(new FormData(event.currentTarget), "amount"); if (amount > 0) updatePlayer(editing.id, (p) => ({ ...p, buyIns: [{ id: makeId(), amount }, ...p.buyIns] })); event.currentTarget.reset(); }}><label>Add buy-in<input name="amount" type="number" inputMode="numeric" min="1" placeholder="50" required /></label><button className="button secondary" type="submit">Add</button></form>
        {editing.buyIns.length > 0 && <div className="buyin-list">{editing.buyIns.map((entry, index) => <div key={entry.id}><span>Buy-in {editing.buyIns.length - index}</span><strong>{entry.amount}</strong><button onClick={() => updatePlayer(editing.id, (p) => ({ ...p, buyIns: p.buyIns.filter((b) => b.id !== entry.id) }))} aria-label={`Remove buy-in ${entry.amount}`}>×</button></div>)}</div>}
        <div className="form-grid"><label>Cash out<input type="number" inputMode="numeric" min="0" value={editing.checkout} onChange={(e) => updatePlayer(editing.id, (p) => ({ ...p, checkout: Math.max(0, Number(e.target.value)) }))} /></label><label>Food / drink paid<input type="number" inputMode="numeric" min="0" value={editing.spent} onChange={(e) => updatePlayer(editing.id, (p) => ({ ...p, spent: Math.max(0, Number(e.target.value)) }))} /></label></div>
        <div className="modal-actions"><button className="text-button danger" onClick={() => { if (window.confirm(`Remove ${editing.name}?`)) { setPlayers((p) => p.filter((item) => item.id !== editing.id)); setEditingId(null); } }}>Remove player</button><button className="button primary" onClick={() => setEditingId(null)}>Done</button></div>
      </div></div>}
    </main>
  );
}
