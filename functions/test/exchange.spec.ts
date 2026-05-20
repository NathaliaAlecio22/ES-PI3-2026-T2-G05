import * as admin from "firebase-admin";
import * as authShared from "../src/exchange/shared/auth";
import fft = require("firebase-functions-test");


process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "demo-invest-test" });


const testEnv = fft({ projectId: "demo-invest-test" });


if (!admin.apps.length) {
  admin.initializeApp();
}


import { api } from "../src/exchange/index";

const db = admin.firestore();

describe("testes da API de exchange/transações", () => {
  beforeAll(() => {
    jest.spyOn(authShared, "requireAuth").mockResolvedValue("investidor-teste-123");
    jest.spyOn(console, "error").mockImplementation(() => {});
  });

  afterAll(() => {
    jest.restoreAllMocks();
    testEnv.cleanup();
  });

  const createRes = () => ({
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
    send: jest.fn().mockReturnThis(),
    setHeader: jest.fn(),
  });

  it("deve criar oferta de compra com sucesso", async () => {
    await db.collection("users").doc("investidor-teste-123").set({ nome: "Maria" });
    await db.collection("startups").doc("startup-1").set({ nome_startup: "MesclaTech" });

    const req = {
      method: "POST",
      path: "/orders/create-offer",
      body: { startupId: "startup-1", quantidade: 10, precoUnitario: 50, tipo: "compra" },
    };
    const res = createRes();

    await api(req as any, res as any);
    expect(res.status).toHaveBeenCalledWith(200);
  });

  it("deve falhar ao tentar vender sem saldo de tokens", async () => {
    await db.collection("users").doc("investidor-teste-123").set({ nome: "Maria", carteira: [] });
    await db.collection("startups").doc("startup-1").set({ nome_startup: "MesclaTech" });

    const req = {
      method: "POST",
      path: "/orders/sell",
      body: { startupId: "startup-1", quantidade: 5, precoUnitario: 50 },
    };
    const res = createRes();

    await api(req as any, res as any);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  it("deve retornar erro 405 para métodos diferentes de post", async () => {
    const req = { method: "GET", path: "/wallet/credit" };
    const res = createRes();

    await api(req as any, res as any);
    expect(res.status).toHaveBeenCalledWith(405);
  });

  it("deve falhar ao tentar criar oferta com dados inválidos, payload incompleto", async () => {
    const req = {
      method: "POST",
      path: "/orders/create-offer",
      body: { startupId: "startup-1" },
    };
    const res = createRes();

    await api(req as any, res as any);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: "invalid-payload" }));
  });

  it("deve falhar ao tentar criar oferta para uma startup que não existe", async () => {
    const req = {
      method: "POST",
      path: "/orders/create-offer",
      body: { startupId: "startup-fantasma", quantidade: 10, precoUnitario: 50, tipo: "compra" },
    };
    const res = createRes();

    await api(req as any, res as any);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: "startup-not-found" }));
  });
});