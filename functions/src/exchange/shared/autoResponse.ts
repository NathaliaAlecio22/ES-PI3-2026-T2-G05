export function getAutoResponse(question: string): string {
  const text = question.toLowerCase();
  const rules: Array<{ keywords: string[]; response: string }> = [
    {
      keywords: ["comprar token", "comprar tokens", "compra"],
      response:
        "Para comprar tokens, você precisa ter saldo disponível e uma oferta de venda aberta no balcão.",
    },
    {
      keywords: ["vender token", "vender tokens", "venda"],
      response:
        "Para vender tokens, você precisa ter tokens na carteira e uma oferta de compra aberta.",
    },
    {
      keywords: ["saldo", "adicionar saldo"],
      response: "Para adicionar saldo, vá em Carteira e escolha um valor.",
    },
    {
      keywords: ["oferta", "criar oferta"],
      response:
        "Você pode criar oferta de compra ou venda no Balcão. Preencha quantidade e preço por token.",
    },
    {
      keywords: ["perguntas privadas", "pergunta privada"],
      response:
        "Perguntas privadas são exclusivas para investidores que já possuem tokens dessa startup.",
    },
    {
      keywords: ["index", "índice", "indice", "erro de lista"],
      response:
        "Se a lista de perguntas não carregar, verifique se o índice composto (startupId + createdAt) está habilitado no Firestore.",
    },
    {
      keywords: ["erro", "não funciona", "nao funciona"],
      response:
        "Se algo falhar, verifique saldo, tokens na carteira e se as Functions estão ativas.",
    },
  ];

  for (const rule of rules) {
    if (rule.keywords.some((keyword: string) => text.includes(keyword))) {
      return rule.response;
    }
  }

  return "Obrigado pela pergunta! Vamos analisar e responder em breve.";
}
