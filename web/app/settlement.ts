export type BuyIn = { id: string; amount: number };
export type Player = { id: string; name: string; buyIns: BuyIn[]; checkout: number; spent: number };

function balancedRoundedValues(exactValues: { id: string; value: number }[]) {
  const candidates = exactValues.map((item, order) => {
    const lowerValue = Math.floor(item.value / 5) * 5;
    return { ...item, order, lowerValue, remainder: item.value - lowerValue };
  });
  const values: Record<string, number> = Object.fromEntries(candidates.map(({ id, lowerValue }) => [id, lowerValue]));
  const lowerTotal = candidates.reduce((sum, item) => sum + item.lowerValue, 0);
  const incrementsNeeded = Math.min(candidates.length, Math.max(0, -lowerTotal / 5));
  const ranked = [...candidates].sort((a, b) => b.remainder - a.remainder || a.order - b.order);
  ranked.slice(0, incrementsNeeded).forEach(({ id }) => { values[id] += 5; });
  return values;
}

export function calculateSettlement(players: Player[]) {
  const facts = players.map((player) => {
    const totalBuyIn = player.buyIns.reduce((sum, entry) => sum + entry.amount, 0);
    const current = player.checkout - totalBuyIn;
    return { player, totalBuyIn, current, winning: current >= 0 };
  });
  const groupWin = facts.filter((item) => item.winning).reduce((sum, item) => sum + item.current, 0);
  const groupLose = facts.filter((item) => !item.winning).reduce((sum, item) => sum + item.current, 0);
  const mismatched = groupWin + groupLose !== 0;

  let adjustments: Record<string, number>;
  if (mismatched) {
    const winnersHaveDeficit = groupWin > Math.abs(groupLose);
    const exact = facts.map(({ player, current, winning }) => {
      let value: number;
      if (winnersHaveDeficit && winning) value = groupWin === 0 ? 0 : Math.abs(groupLose) * current / groupWin;
      else if (winnersHaveDeficit || winning) value = current;
      else value = groupLose === 0 ? 0 : -groupWin * current / groupLose;
      return { id: player.id, value };
    });
    adjustments = balancedRoundedValues(exact);
  } else {
    adjustments = Object.fromEntries(facts.map(({ player, current }) => [player.id, current]));
  }

  const groupSpent = players.reduce((sum, player) => sum + Math.max(0, player.spent), 0);
  const adjustedGroupWin = Object.values(adjustments).filter((value) => value > 0).reduce((a, b) => a + b, 0);
  const exactFinal = players.map((player) => {
    const adjustment = adjustments[player.id] ?? 0;
    let foodShare = 0;
    if (adjustedGroupWin > 0 && adjustment > 0) foodShare = adjustment / adjustedGroupWin * groupSpent;
    else if (adjustedGroupWin === 0 && players.length > 0) foodShare = groupSpent / players.length;
    return { id: player.id, value: adjustment - foodShare + Math.max(0, player.spent) };
  });

  const difference = groupWin - Math.abs(groupLose);
  return {
    adjustments,
    finalValues: balancedRoundedValues(exactFinal),
    groupWin,
    groupLose,
    groupSpent,
    mismatched,
    showDiff: mismatched || groupSpent > 0,
    totalIn: facts.reduce((sum, item) => sum + item.totalBuyIn, 0),
    totalOut: players.reduce((sum, player) => sum + player.checkout, 0),
    balanceLabel: difference > 0 ? "Deficit" : "Surplus",
    balanceAmount: Math.abs(difference),
  };
}
