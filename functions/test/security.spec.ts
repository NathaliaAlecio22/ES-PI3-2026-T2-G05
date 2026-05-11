import { initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';

let testEnv: RulesTestEnvironment;

describe('Segurança do App', () => {
    beforeAll(async () => {
        testEnv = await initializeTestEnvironment({
            projectId: 'pi-iii-d8570',
            firestore: {
                rules: readFileSync('../firestore.rules', 'utf8'),
                host: '127.0.0.1',
                port: 8080     
            },
        });
    });

    it('barrar criação de oferta sem mfa', async () => {
        const context = testEnv.authenticatedContext('user123'); 
        const db = context.firestore();
        const doc = db.collection('ofertas_investidores').doc('o1');

        await expect(doc.set({ valor: 100 })).rejects.toThrow();
    });

    it('permitir criação de oferta com mfa', async () => {
        const context = testEnv.authenticatedContext('user123', {
            firebase: { sign_in_second_factor: 'phone' }
        } as any);
        const db = context.firestore();
        const doc = db.collection('ofertas_investidores').doc('o2');

        await doc.set({ valor: 100, startupId: 'puc1' });
    });

    afterAll(async () => {
    await testEnv.cleanup();
  });
});