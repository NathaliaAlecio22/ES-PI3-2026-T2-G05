export function getNumber(value: unknown): number | null {
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

export function getString(value: unknown): string | null {
  if (typeof value === "string") {
    return value.trim();
  }
  return null;
}
