import { onCall } from "firebase-functions/v2/https";
import { getAllStartups } from "../repositories/startupRepository";

export const listStartups = onCall({ region: "southamerica-east1" }, async (request) => {
    try {
        const startups = await getAllStartups();
        return { 
            status: "success", 
            data: startups 
        };
    } catch (error) {
        return { 
            status: "error", 
            message: "Erro ao buscar startups" 
        };
    }
});