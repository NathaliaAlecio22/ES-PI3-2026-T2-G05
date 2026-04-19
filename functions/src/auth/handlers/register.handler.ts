import * as functions from "firebase-functions";

export const register = functions.https.onRequest((req, res) => {
  res.send("Cadastro funcionando");
});