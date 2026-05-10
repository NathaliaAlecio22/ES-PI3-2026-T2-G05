
import { db } from "../../startups/shared/firebase"; 
import { FieldValue } from "firebase-admin/firestore";

export async function atualizarCarteiraEInvestimento(data: any) {
    const { user_id, startup_id, quantidade_tokens, valor_unidade, tipo, valor_total, nome_startup } = data;
    const carteiraRef = db.doc(`users/${user_id}/carteira/${startup_id}`);
    const userRef = db.doc(`users/${user_id}`);

    return db.runTransaction(async (t) => {
        const carteiraDoc = await t.get(carteiraRef);
        if (tipo === "compra") {
            t.update(userRef, { saldo: FieldValue.increment(-valor_total) });

            if (!carteiraDoc.exists) {
                t.set(carteiraRef, {
                    nome_startup,
                    startup_id,
                    quantidade_tokens,
                    preco_medio: valor_unidade,
                    valor_investido_total: valor_total,
                    data_ultima_atualizacao: FieldValue.serverTimestamp()
                });
            } else {
                const atual = carteiraDoc.data() || {};
                const novaQtde = (atual.quantidade_tokens || 0) + quantidade_tokens;
                const novoInvestimento = (atual.valor_investido_total || 0) + valor_total;
                
                t.update(carteiraRef, {
                    quantidade_tokens: novaQtde,
                    valor_investido_total: novoInvestimento,
                    preco_medio: novoInvestimento / novaQtde,
                    data_ultima_atualizacao: FieldValue.serverTimestamp()
                });
            }
        }
    });
}