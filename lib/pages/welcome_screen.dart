// Antônio Airton R. Juinor - 24794851

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatefulWidget {
  //função obrigatória que serve pra avisar a main que o Onboarding acabou e que deve mostrar o login
  final VoidCallback aoFinalizar;

  //construtor. o required força que quem abrir esta tela precise passar a função aoFinalizar
  const WelcomeScreen({super.key, required this.aoFinalizar});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  //controlador responsável por fazer a página deslizar para a próxima página
  final PageController _pageController = PageController();

  //variável que guarda qual página do onboarding o usuário está
  int _currentPage = 0;

  //lista de mapas que estão os dados de cada página
  final List<Map<String, dynamic>> _onboardingData = [
    //pagina 1
    {
      'isFirstPage': true,
      'title': 'InvestUp!',
      'description':
          'O futuro do investimento em startups na palma da sua mão. Conecte-se com grandes ideias inovadoras.',
    },

    //pagina 2
    {
      'isFirstPage': false,
      //arquivo lottie da animação
      'lottiePath': 'assets/startup.json',
      'title': 'Negocie Tokens',
      'description':
          'Simule a compra, venda e troca de frações/tokens das startups mais promissoras do ecossistema de inovação.',
    },

    //pagina 3
    {
      'isFirstPage': false,
      //arquivo lottie da animação
      'lottiePath': 'assets/dashboard.json',
      'title': 'Dashboard Inteligente',
      'description':
          'Monitore a valorização dos seus investimentos, saldo em conta e tendências de mercado com gráficos em tempo real.',
    },
  ];

  @override
  //função que é chamada quando a tela é destruída
  void dispose() {
    _pageController.dispose(); //limpa o controlador da ram
    super.dispose(); //chama o dispose da classe mãe
  }

  //metodo que apenas executa a função aoFinalizar que foi recebida no construtor
  void _finalizarOnboarding() {
    widget
        .aoFinalizar(); //usado para acessar as variáveis da classe WelcomeScreen a partir do State
  }

  //constrói o visual da tela
  @override
  Widget build(BuildContext context) {
    //estrutura basica da tela
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            //gradiente
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C1B), Color(0xFF1D1435), Color(0xFF331F52)],
          ),
        ),

        //garante que o conteúdo fique dentro da área segura do dispositivo
        child: SafeArea(
          //coluna que organiza os elementos verticalmente
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  //verifica se o usuário não está na última página, se não estiver mostra o botão pular, caso contrário mostra um espaço vazio para manter o alinhamento
                  child: _currentPage != _onboardingData.length - 1
                      ? TextButton(
                          onPressed:
                              _finalizarOnboarding, //chama a função para finalizar o onboarding
                          child: const Text(
                            'Pular',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : const SizedBox(height: 48),
                ),
              ),

              //faz com que o PageView ocupe todo o espaço disponível entre o topo e a parte de baixo da tela
              Expanded(
                //constrói o PageView, que é o componente que permite deslizar entre as páginas
                child: PageView.builder(
                  controller:
                      _pageController, //controlador para controlar a página atual
                  onPageChanged: (int page) => setState(
                    () => _currentPage = page,
                  ), //atualiza a variável _currentPage quando o usuário desliza para uma nova página
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    final item =
                        _onboardingData[index]; //pega os dados da página atual
                    bool isFirst =
                        item['isFirstPage'] ==
                        true; //verifica se é a primeira página

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //se for a primeira página, mostra o logo e o título, caso contrário mostra a animação e o título da página
                          if (isFirst) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Image.asset(
                                'assets/Logo.png',
                                height: 200,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'InvestUp!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Powered by MesclaInvest',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.4),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            Lottie.asset(
                              item['lottiePath'],
                              height: 220,
                              fit: BoxFit
                                  .contain, //para a animação não ficar esticada ou cortada
                            ),
                            const SizedBox(height: 40),
                            Text(
                              item['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],

                          //sendo a primeira página ou não, mostra a descrição da página
                          const SizedBox(height: 20),
                          Text(
                            item['description'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              //rodapé
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      //gera os indicadores de página com base na quantidade de páginas
                      children: List.generate(
                        _onboardingData.length,
                        (index) => AnimatedContainer(
                          //animação para o indicador de página, que muda de tamanho e cor
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFFE0AAFF)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          //se não estiver na ultima pagina
                          if (_currentPage < _onboardingData.length - 1) {
                            _pageController.nextPage(
                              //faz a página deslizar para a próxima página
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            );
                          } else {
                            //se estiver na última página, finaliza o onboarding
                            _finalizarOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFC4B5FD)],
                            ),
                          ),

                          //centra o texto e o ícone dentro do botão
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                //o texto do botão muda dependendo se o usuário está na última página ou não
                                Text(
                                  _currentPage == _onboardingData.length - 1
                                      ? 'Começar a Investir'
                                      : 'Próximo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  //também muda o ícone dependendo se o usuário está na última página ou não
                                  _currentPage == _onboardingData.length - 1
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
