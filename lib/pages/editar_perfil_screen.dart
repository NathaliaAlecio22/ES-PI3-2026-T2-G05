import 'package:flutter/material.dart';

class EditarPerfilScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1117),
      appBar: AppBar(
        title: Text("Editar Perfil"),
        backgroundColor: Color(0xFF7B2FF7),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            buildField("Nome"),
            buildField("E-mail"),
            buildField("Telefone"),

            // CPF BLOQUEADO
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: "CPF",
                suffixIcon: Icon(Icons.lock),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
