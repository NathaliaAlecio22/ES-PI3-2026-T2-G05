import * as admin from "firebase-admin";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import type { Request, Response } from "express";

admin.initializeApp();

const db = getFirestore();

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

function setCors(res: Response): void {
  Object.entries(corsHeaders).forEach(([key, value]) => {
    res.setHeader(key, value);
  });
}

function parseBody(req: Request): Record<string, unknown> {
  if (req.body && typeof req.body === "object") {
    return req.body as Record<string, unknown>;
  }
  if (typeof req.body === "string") {
    try {
      return JSON.parse(req.body) as Record<string, unknown>;
    } catch {
      return {};
    }
  }
  return {};
}

async function requireAuth(req: Request): Promise<string> {
  const header = req.headers.authorization ?? "";
  const match = header.match(/^Bearer (.+)$/);
  if (!match) {
    throw new Error("missing-auth-token");
  }
  const token = match[1];
  const decoded = await admin.auth().verifyIdToken(token);
  return decoded.uid;
}

function getNumber(value: unknown): number | null {
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function getString(value: unknown): string | null {
  if (typeof value === "string") {
    return value.trim();
  }
  return null;
}

type CarteiraItem = {
  startup_id: string;
  startup_nome: string;
  quantidade: number;
};

function updateCarteira(
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

function getAutoResponse(question: string): string {
  const text = question.toLowerCase();
  const rules: Array<{ keywords: string[]; response: string }> = [
    {
      keywords: ["comprar token", "comprar tokens", "compra"],
      response:
        "Para comprar tokens, você precisa ter saldo disponível e uma oferta de venda aberta no balcão.",
    },
    {
      keywords: ["vender token", "vender tokens", "venda"],
      response:
        "Para vender tokens, você precisa ter tokens na carteira e uma oferta de compra aberta.",
    },
    {
      keywords: ["saldo", "adicionar saldo"],
      response:
        "Para adicionar saldo, vá em Carteira e escolha um valor.",
    },
    {
      keywords: ["oferta", "criar oferta"],
      response:
        "Você pode criar oferta de compra ou venda no Balcão. Preencha quantidade e preço por token.",
    },
    {
      keywords: ["perguntas privadas", "pergunta privada"],
      response:
        "Perguntas privadas são exclusivas para investidores que já possuem tokens dessa startup.",
    },
    {
      keywords: ["index", "índice", "indice", "erro de lista"],
      response:
        "Se a lista de perguntas não carregar, verifique se o índice composto (startupId + createdAt) está habilitado no Firestore.",
    },
    {
      keywords: ["erro", "não funciona", "nao funciona"],
      response:
        "Se algo falhar, verifique saldo, tokens na carteira e se as Functions estão ativas.",
    },
  ];

  for (const rule of rules) {
    if (rule.keywords.some((keyword: string) => text.includes(keyword))) {
      return rule.response;
    }
  }

  return "Obrigado pela pergunta! Vamos analisar e responder em breve.";
}

export const api = onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({ error: "method-not-allowed" });
    return;
  }

  try {
    const uid = await requireAuth(req);
    const body = parseBody(req);
    const path = req.path;

    console.log("api-request", {
      path,
      uid,
      keys: Object.keys(body),
    });

    if (path === "/wallet/credit") {
      const amount = getNumber(body.amount);
      if (amount == null || amount <= 0) {
        res.status(400).json({ error: "invalid-amount" });
        return;
      }

      const userRef = db.collection("users").doc(uid);
      await db.runTransaction(async (tx) => {
        const userSnap = await tx.get(userRef);
        const saldoAtual = (userSnap.get("saldo") as number | undefined) ?? 0;
        tx.set(userRef, { saldo: saldoAtual + amount }, { merge: true });
      });

      res.status(200).json({ ok: true });
      return;
    }

    if (path === "/qa/auto-response") {
      const question = getString(body.question);
      if (!question) {
        res.status(400).json({ error: "invalid-question" });
        return;
      }

      res.status(200).json({ answer: getAutoResponse(question) });
      return;
    }

    if (path === "/orders/create-offer") {
      const startupId = getString(body.startupId);
      const quantidade = getNumber(body.quantidade);
      const precoUnitario = getNumber(body.precoUnitario);
      const tipo = getString(body.tipo) ?? "compra";

      if (!startupId || quantidade == null || precoUnitario == null) {
        res.status(400).json({ error: "invalid-payload" });
        return;
      }

      if (quantidade <= 0 || precoUnitario <= 0) {
        res.status(400).json({ error: "invalid-values" });
        return;
      }

      if (tipo !== "compra") {
        res.status(400).json({ error: "invalid-offer-type" });
        return;
      }

      const startupRef = db.collection("startups").doc(startupId);
      const userRef = db.collection("users").doc(uid);

      await db.runTransaction(async (tx) => {
        const [startupSnap, userSnap] = await Promise.all([
          tx.get(startupRef),
          tx.get(userRef),
        ]);

        if (!startupSnap.exists) {
          throw new Error("startup-not-found");
        }

        const startupData = startupSnap.data() ?? {};
        const startupNome = String(startupData.nome_startup ?? "Startup");
        const userData = userSnap.data() ?? {};
        const investidorNome = String(userData.nome ?? "Investidor");

        const offerRef = db.collection("ofertas_investidores").doc();
        tx.set(offerRef, {
          tipo: "compra",
          status: "aberta",
          startup_id: startupId,
          startup_nome: startupNome,
          investidor_id: uid,
          investidor_nome: investidorNome,
          preco_unitario: precoUnitario,
          quantidade_total: quantidade,
          quantidade_disponivel: quantidade,
          created_at: FieldValue.serverTimestamp(),
        });
      });

      res.status(200).json({ ok: true });
      return;
    }

    if (path === "/orders/sell") {
      const startupId = getString(body.startupId);
      const quantidade = getNumber(body.quantidade);
      const precoUnitario = getNumber(body.precoUnitario);

      if (!startupId || quantidade == null || precoUnitario == null) {
        res.status(400).json({ error: "invalid-payload" });
        return;
      }

      if (quantidade <= 0 || precoUnitario <= 0) {
        res.status(400).json({ error: "invalid-values" });
        return;
      }

      const startupRef = db.collection("startups").doc(startupId);
      const userRef = db.collection("users").doc(uid);

      await db.runTransaction(async (tx) => {
        const [startupSnap, userSnap] = await Promise.all([
          tx.get(startupRef),
          tx.get(userRef),
        ]);

        if (!startupSnap.exists) {
          throw new Error("startup-not-found");
        }

        const startupData = startupSnap.data() ?? {};
        const startupNome = String(startupData.nome_startup ?? "Startup");
        const userData = userSnap.data() ?? {};
        const investidorNome = String(userData.nome ?? "Investidor");
        const carteira = (userData.carteira as CarteiraItem[] | undefined) ?? [];
        const item = carteira.find((c) => c.startup_id === startupId);
        const disponivel = item?.quantidade ?? 0;

        if (disponivel < quantidade) {
          throw new Error("insufficient-tokens");
        }

        const novaCarteira = updateCarteira(
          carteira,
          startupId,
          startupNome,
          -quantidade,
        );

        const offerRef = db.collection("ofertas_investidores").doc();
        tx.set(offerRef, {
          tipo: "venda",
          status: "aberta",
          startup_id: startupId,
          startup_nome: startupNome,
          investidor_id: uid,
          investidor_nome: investidorNome,
          preco_unitario: precoUnitario,
          quantidade_total: quantidade,
          quantidade_disponivel: quantidade,
          created_at: FieldValue.serverTimestamp(),
        });

        tx.set(userRef, { carteira: novaCarteira }, { merge: true });
      });

      res.status(200).json({ ok: true });
      return;
    }

    if (path === "/orders/buy") {
      const offerId = getString(body.offerId);
      const quantidade = getNumber(body.quantidade);

      if (!offerId || quantidade == null || quantidade <= 0) {
        res.status(400).json({ error: "invalid-payload" });
        return;
      }

      const offerRef = db.collection("ofertas_investidores").doc(offerId);
      const buyerRef = db.collection("users").doc(uid);

      await db.runTransaction(async (tx) => {
        const offerSnap = await tx.get(offerRef);
        if (!offerSnap.exists) {
          throw new Error("offer-not-found");
        }

        const offerData = offerSnap.data() ?? {};
        if (offerData.status !== "aberta" || offerData.tipo !== "venda") {
          throw new Error("offer-not-available");
        }

        const quantidadeDisponivel = Number(offerData.quantidade_disponivel ?? 0);
        if (quantidade > quantidadeDisponivel) {
          throw new Error("insufficient-offer-quantity");
        }

        const precoUnitario = Number(offerData.preco_unitario ?? 0);
        const total = quantidade * precoUnitario;

        const sellerId = String(offerData.investidor_id ?? "");
        if (!sellerId) {
          throw new Error("invalid-seller");
        }

        const sellerRef = db.collection("users").doc(sellerId);
        const [buyerSnap, sellerSnap] = await Promise.all([
          tx.get(buyerRef),
          tx.get(sellerRef),
        ]);

        const buyerData = buyerSnap.data() ?? {};
        const buyerSaldo = Number(buyerData.saldo ?? 0);
        if (buyerSaldo < total) {
          throw new Error("insufficient-balance");
        }

        const sellerData = sellerSnap.data() ?? {};
        const sellerSaldo = Number(sellerData.saldo ?? 0);

        const startupId = String(offerData.startup_id ?? "");
        const startupNome = String(offerData.startup_nome ?? "Startup");
        const buyerCarteira = (buyerData.carteira as CarteiraItem[] | undefined) ?? [];
        const novaCarteira = updateCarteira(
          buyerCarteira,
          startupId,
          startupNome,
          quantidade,
        );

        tx.set(buyerRef, { saldo: buyerSaldo - total, carteira: novaCarteira }, { merge: true });
        tx.set(sellerRef, { saldo: sellerSaldo + total }, { merge: true });

        const novaDisponivel = quantidadeDisponivel - quantidade;
        const offerUpdate: Record<string, unknown> = {
          quantidade_disponivel: novaDisponivel,
        };
        if (novaDisponivel <= 0) {
          offerUpdate.status = "concluida";
        }
        tx.set(offerRef, offerUpdate, { merge: true });
      });

      res.status(200).json({ ok: true });
      return;
    }

    if (path === "/orders/accept-buy") {
      const offerId = getString(body.offerId);
      const quantidade = getNumber(body.quantidade);

      if (!offerId || quantidade == null || quantidade <= 0) {
        res.status(400).json({ error: "invalid-payload" });
        return;
      }

      const offerRef = db.collection("ofertas_investidores").doc(offerId);
      const sellerRef = db.collection("users").doc(uid);

      await db.runTransaction(async (tx) => {
        const offerSnap = await tx.get(offerRef);
        if (!offerSnap.exists) {
          throw new Error("offer-not-found");
        }

        const offerData = offerSnap.data() ?? {};
        if (offerData.status !== "aberta" || offerData.tipo !== "compra") {
          throw new Error("offer-not-available");
        }

        const quantidadeDisponivel = Number(offerData.quantidade_disponivel ?? 0);
        if (quantidade > quantidadeDisponivel) {
          throw new Error("insufficient-offer-quantity");
        }

        const precoUnitario = Number(offerData.preco_unitario ?? 0);
        const total = quantidade * precoUnitario;

        const buyerId = String(offerData.investidor_id ?? "");
        if (!buyerId) {
          throw new Error("invalid-buyer");
        }

        const buyerRef = db.collection("users").doc(buyerId);
        const [sellerSnap, buyerSnap] = await Promise.all([
          tx.get(sellerRef),
          tx.get(buyerRef),
        ]);

        const sellerData = sellerSnap.data() ?? {};
        const sellerCarteira = (sellerData.carteira as CarteiraItem[] | undefined) ?? [];

        const startupId = String(offerData.startup_id ?? "");
        const startupNome = String(offerData.startup_nome ?? "Startup");
        const item = sellerCarteira.find((c) => c.startup_id === startupId);
        const disponivel = item?.quantidade ?? 0;

        if (disponivel < quantidade) {
          throw new Error("insufficient-tokens");
        }

        const buyerData = buyerSnap.data() ?? {};
        const buyerSaldo = Number(buyerData.saldo ?? 0);
        if (buyerSaldo < total) {
          throw new Error("insufficient-balance");
        }

        const buyerCarteira = (buyerData.carteira as CarteiraItem[] | undefined) ?? [];
        const novaCarteiraBuyer = updateCarteira(
          buyerCarteira,
          startupId,
          startupNome,
          quantidade,
        );
        const novaCarteiraSeller = updateCarteira(
          sellerCarteira,
          startupId,
          startupNome,
          -quantidade,
        );

        const sellerSaldo = Number(sellerData.saldo ?? 0);

        tx.set(buyerRef, { saldo: buyerSaldo - total, carteira: novaCarteiraBuyer }, { merge: true });
        tx.set(sellerRef, { saldo: sellerSaldo + total, carteira: novaCarteiraSeller }, { merge: true });

        const novaDisponivel = quantidadeDisponivel - quantidade;
        const offerUpdate: Record<string, unknown> = {
          quantidade_disponivel: novaDisponivel,
        };
        if (novaDisponivel <= 0) {
          offerUpdate.status = "concluida";
        }
        tx.set(offerRef, offerUpdate, { merge: true });
      });

      res.status(200).json({ ok: true });
      return;
    }

    res.status(404).json({ error: "route-not-found" });
  } catch (error) {
    const message = error instanceof Error ? error.message : "internal-error";
    console.error("api-error", { message, path: req.path });
    res.status(400).json({ error: message });
  }
});
