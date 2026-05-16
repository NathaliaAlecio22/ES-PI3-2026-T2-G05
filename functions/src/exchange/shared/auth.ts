import type { Request } from "express";
import * as admin from "firebase-admin";

export async function requireAuth(req: Request): Promise<string> {
  const header = req.headers.authorization ?? "";
  const match = header.match(/^Bearer (.+)$/);
  if (!match) {
    throw new Error("missing-auth-token");
  }
  const token = match[1];
  const decoded = await admin.auth().verifyIdToken(token);
  return decoded.uid;
}
