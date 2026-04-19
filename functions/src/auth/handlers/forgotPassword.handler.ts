import * as functions from "firebase-functions";

export const forgotPassword = functions.https.onRequest((req, res) => {
  res.send("Recuperação de senha funcionando");
});