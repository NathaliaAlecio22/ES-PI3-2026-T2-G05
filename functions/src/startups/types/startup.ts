export interface Socio {
    nome_socio: string;
    participacao_societaria: number | string;
}

export interface FAQ {
    pergunta: string;
    resposta: string;
}

export interface Startup {
    id?: string;
    nome_startup: string;
    setor: string;
    status: string;
    estagio: string;
    descricao: string;
    sumario_executivo: string;
    capital_aportado: number;
    tokens_emitidos: number;
    video_demo: string;
    mentores_conselho: string[];
    estrutura_societaria: Socio[];
    faqs_publicas: FAQ[];
}