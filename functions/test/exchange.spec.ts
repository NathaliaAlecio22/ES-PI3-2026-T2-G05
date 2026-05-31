// Antônio Airton R. Juinor - 24794851

//importações necessárias para os testes
import * as admin from "firebase-admin";
import * as authShared from "../src/exchange/shared/auth";
import fft = require("firebase-functions-test");

//força o uso do emulador do Firestore para os testes
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
//nome do projeto de teste
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "demo-invest-test" });

//inicializa o ambiente de teste do Firebase Functions
const testEnv = fft({ projectId: "demo-invest-test" });

//garante que o Firebase Admin SDK seja inicializado apenas uma vez
if (!admin.apps.length) {
  admin.initializeApp();
}

//importa a função da API de exchange para ser testada
import { api } from "../src/exchange/index";

//atalho para acessar o Firestore
const db = admin.firestore();


//criação dos testes para a API de exchange/transações
describe("testes da API de exchange/transações", () => {

  beforeAll(() => {
    //diz que o usuário sempre estará autenticado
    jest.spyOn(authShared, "requireAuth").mockResolvedValue("investidor-teste-123");
    //retira os logs de erro do console
    jest.spyOn(console, "error").mockImplementation(() => {});
  });

   //depois de todos os testes
  afterAll(() => {
    //desfaz a simulação da autenticação
    jest.restoreAllMocks();
    //limpa o ambiente de teste do Firebase Functions
    testEnv.cleanup();
  });

  //objeto falso de resposta http
  const createRes = () => ({
    status: jest.fn().mockReturnThis(), //anota qual status foi enviado
    json: jest.fn().mockReturnThis(),   //anota qual json foi enviado
    send: jest.fn().mockReturnThis(),  //anota qual resposta foi enviada
    setHeader: jest.fn(),     //anota quais headers foram enviados
  });


  //inicio dos testes


  it("deve criar oferta de compra com sucesso", async () => {
    //prepara o ambiente criando um usuário e uma startup
    await db.collection("users").doc("investidor-teste-123").set({ nome: "Maria" });
    await db.collection("startups").doc("startup-1").set({ nome_startup: "MesclaTech" });

    //cria uma requisição falsa para criar uma oferta de compra
    const req = {
      method: "POST",
      path: "/orders/create-offer",
      body: { startupId: "startup-1", quantidade: 10, precoUnitario: 50, tipo: "compra" },
    };
    //anota a resposta
    const res = createRes();

    //chama a função da API com a requisição e resposta
    await api(req as any, res as any);
    //verifica se o status 200 foi enviado, indicando sucesso
    expect(res.status).toHaveBeenCalledWith(200);
  });


  it("deve falhar ao tentar vender sem saldo de tokens", async () => {
    //prepara o ambiente criando um usuário sem tokens e uma startup
    await db.collection("users").doc("investidor-teste-123").set({ nome: "Maria", carteira: [] });
    await db.collection("startups").doc("startup-1").set({ nome_startup: "MesclaTech" });

    //cria uma requisição falsa para tentar vender tokens de uma startup
    const req = {
      method: "POST",
      path: "/orders/sell",
      body: { startupId: "startup-1", quantidade: 5, precoUnitario: 50 },
    };
    //anota a resposta
    const res = createRes();

    //chama a função da API com a requisição e resposta
    await api(req as any, res as any);
    expect(res.status).toHaveBeenCalledWith(400); //verifica se o status 400 foi enviado, indicando erro
  });


  it("deve retornar erro 405 para métodos diferentes de post", async () => {
    //cria uma requisição falsa usando o método GET, que não é permitido para essa rota
    const req = { method: "GET", path: "/wallet/credit" };
    const res = createRes();

    //chama a função da API com a requisição e resposta
    await api(req as any, res as any);
    
    //verifica se o status 405 foi enviado, indicando método não permitido
    expect(res.status).toHaveBeenCalledWith(405);
  });


  it("deve falhar ao tentar criar oferta com dados inválidos, payload incompleto", async () => {

    //cria uma requisição falsa para criar uma oferta, mas sem os campos necessários, apenas com o id da startup
    const req = {
      method: "POST",
      path: "/orders/create-offer",
      body: { startupId: "startup-1" },
    };
    const res = createRes();

    //chama a função da API com a requisição e resposta
    await api(req as any, res as any);
    //verifica se o status 400 foi enviado
    expect(res.status).toHaveBeenCalledWith(400);
    //verifica se o json enviado contém um campo de erro indicando payload inválido
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: "invalid-payload" }));
  });


  it("deve falhar ao tentar criar oferta para uma startup que não existe", async () => {
    //cria uma requisição falsa para criar uma oferta, mas com um id de startup que não existe no banco
    const req = {
      method: "POST",
      path: "/orders/create-offer",
      body: { startupId: "startup-fantasma", quantidade: 10, precoUnitario: 50, tipo: "compra" },
    };
    const res = createRes();

    //chama a função da API com a requisição e resposta
    await api(req as any, res as any);
    //verifica se o status 400 foi enviado
    expect(res.status).toHaveBeenCalledWith(400);
    //verifica se o json enviado contém um campo de erro indicando que a startup não foi encontrada
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: "startup-not-found" }));
  });


  it("deve retornar uma resposta automatica", async () => {
    //cria uma requisição falsa para a rota de resposta automática, com uma pergunta no corpo da requisição
    const req = {
      method: "POST",
      path: "/qa/auto-response",
      body: { question: "erro" },
    };
    const res = createRes();

    //chama a função da API com a requisição e resposta
    await api(req as any, res as any);
    //verifica se o status 200 foi enviado, indicando sucesso
    expect(res.status).toHaveBeenCalledWith(200);
    //verifica se o json enviado contém um campo de resposta, que deve ser uma string, indicando que a resposta automática foi gerada
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ answer: expect.any(String) }));
  });
});
