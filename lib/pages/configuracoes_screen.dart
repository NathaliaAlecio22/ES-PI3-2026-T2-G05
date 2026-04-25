import 'package:flutter/material.dart';
import 'editar_perfil_screen.dart';

class ConfiguracoesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Column(
        children: [
          // HEADER GRADIENTE
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B2FF7), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white),
                    Row(
                      children: [
                        Text(
                          "Configurações",
                          style: TextStyle(color: Colors.white, fontSize: 22),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditarPerfilScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(width: 24),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Text("M", style: TextStyle(fontSize: 24)),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Maria Silva",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          Text(
                            "alicebeserra05@gmail.com",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // CONTEÚDO
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Informações da conta",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 16),

                  buildItem(Icons.email, "E-mail", "alicebeserra05@gmail.com"),
                  buildItem(Icons.phone, "Telefone", "(11) 98765-4321"),
                  buildItem(Icons.badge, "CPF", "123.456.789-00"),

                  Spacer(),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Excluir conta"),
                          content: Text(
                            "Tem certeza que deseja excluir sua conta?\n\nVocê perderá:\n- Seus dados\n- Tokens/créditos\n- Saldo em conta\n\nEssa ação é irreversível.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancelar"),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                "Excluir",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text("Excluir conta"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(IconData icon, String title, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white70)),
              Text(value, style: TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
