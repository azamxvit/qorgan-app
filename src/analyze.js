const BANKS = ["kaspi", "каспи", "halyk", "халык", "халық", "jusan", "жусан", "freedom", "фридом", "forte", "форте", "bcc", "банк", "bank"];
const URGENCY = ["срочно", "немедленно", "шұғыл", "жедел", "соңғы", "последн", "минут", "сейчас же", "қазір"];
const PRESSURE = ["заблок", "бұғат", "буғат", "штраф", "айыппұл", "закро", "жабыл", "арест"];
const SECRETS = ["код", "code", "otp", "пароль", "құпиясөз", "cvv", "пин", "растау", "подтверд"];

function hits(text, words) {
  return words.filter((word) => text.includes(word));
}

function suspiciousLink(text) {
  const match = text.match(/https?:\/\/[^\s]+|www\.[^\s]+/i);
  if (!match) return null;
  const url = match[0].toLowerCase();
  const official = ["kaspi.kz", "halykbank.kz", "bankffin.kz", "jusan.kz", "forte.kz"];
  return { url: match[0], trusted: official.some((host) => url.includes(host)) };
}

export function analyzeMessage(raw) {
  const text = raw.toLowerCase();
  const reasons = [];
  let score = 0;
  const banks = hits(text, BANKS);
  const urgency = hits(text, URGENCY);
  const pressure = hits(text, PRESSURE);
  const secrets = hits(text, SECRETS);
  const link = suspiciousLink(text);

  if (banks.length) {
    score += 1;
    reasons.push("Есть название банка.");
  }
  if (urgency.length) {
    score += 2;
    reasons.push("Есть срочность.");
  }
  if (pressure.length) {
    score += 2;
    reasons.push("Есть давление: блок, штраф или закрытие.");
  }
  if (secrets.length) {
    score += 3;
    reasons.push("Просят код или пароль.");
  }
  if (link && !link.trusted) {
    score += 3;
    reasons.push("Ссылка не на официальный сайт банка.");
  }

  if (!reasons.length) reasons.push("Признаков социальной инженерии нет.");

  return {
    verdict: score >= 4 ? "block" : "allow",
    score,
    reasons,
  };
}

export const samples = [
  {
    id: "phish",
    label: "Фишинг",
    text: "KASPI: Счёт заблокируют через 15 минут. Срочно подтвердите код: http://kaspi-secure.xyz/login",
  },
  {
    id: "ok",
    label: "Обычное",
    text: "Halyk Bank: Поступление 20 000 ₸. Доступно 145 300 ₸.",
  },
];
