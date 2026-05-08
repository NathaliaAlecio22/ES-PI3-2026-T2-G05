import * as functions from "firebase-functions";

export const login = functions.https.onRequest((req, res) => {
  res.send("Login funcionando");
});