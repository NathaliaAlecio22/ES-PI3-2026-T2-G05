import { db } from "../shared/firebase";
import { Startup } from "../types/startup";

export async function getAllStartups(): Promise<Startup[]> {
    const snapshot = await db.collection("startups").get();
    
    return snapshot.docs.map(doc => {
        const data = doc.data();
        return {
            id: doc.id,
            ...data
        } as Startup;
    });
}