import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { atualizarCarteiraEInvestimento } from "../repositories/exchangeRepository";

export const processarTransacao = onDocumentCreated(
    { 
        document: "transacoes/{transacaoId}",
        region: "southamerica-east1"
    }, 
    async (event) => {
        const snap = event.data;
        if (!snap) return;

        const data = snap.data();

        
        if (!data.valor_total || data.valor_total <= 0 || !data.valor_unidade || data.valor_unidade <= 0) {
            logger.error("Erro, valor zero ou ausente");
            return;
        }

        try {
            await atualizarCarteiraEInvestimento(data);
            logger.info("Sucesso");
        } catch (e) {
            logger.error("Erro", e);
        }
    }
);