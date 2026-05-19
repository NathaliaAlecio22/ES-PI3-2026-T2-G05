import type { CarteiraItem } from "../types/carteira.types";

export function updateCarteira(
  carteira: CarteiraItem[],
  startupId: string,
  startupNome: string,
  deltaQuantidade: number,
): CarteiraItem[] {
  const updated = [...carteira];
  const index = updated.findIndex((item) => item.startup_id === startupId);
  if (index >= 0) {
    const item = updated[index];
    const novaQuantidade = (item.quantidade ?? 0) + deltaQuantidade;
    if (novaQuantidade <= 0) {
      updated.splice(index, 1);
    } else {
      updated[index] = {
        startup_id: item.startup_id,
        startup_nome: item.startup_nome || startupNome,
        quantidade: novaQuantidade,
      };
    }
    return updated;
  }

  if (deltaQuantidade > 0) {
    updated.push({
      startup_id: startupId,
      startup_nome: startupNome,
      quantidade: deltaQuantidade,
    });
  }

  return updated;
}
