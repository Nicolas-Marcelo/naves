import 'package:flutter/material.dart';

import 'auth_controller.dart';

class TelaPerfil extends StatelessWidget {
  const TelaPerfil({super.key, required this.auth});

  final AuthController auth;

  static const _azul = Color(0xFF102F46);
  static const _fundo = Color(0xFFF3F6F8);

  Future<void> _logout(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja realmente sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não identificado.')),
      );
    }

    final inicial = user.name.trim().isNotEmpty
        ? user.name.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: Colors.transparent,
        title: const Text('Minha conta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: _azul,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            user.name,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            user.email,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F7F87)),
          ),

          const SizedBox(height: 28),

          _CardInformacao(
            icon: Icons.person_outline,
            titulo: 'Nome',
            valor: user.name,
          ),

          const SizedBox(height: 12),

          _CardInformacao(
            icon: Icons.email_outlined,
            titulo: 'E-mail',
            valor: user.email,
          ),

          const SizedBox(height: 12),

          _CardInformacao(
            icon: Icons.verified_user_outlined,
            titulo: 'Situação da conta',
            valor: _descricaoStatus(user.status),
          ),

          const SizedBox(height: 12),

          _CardInformacao(
            icon: Icons.badge_outlined,
            titulo: 'Tipo de usuário',
            valor: _descricaoRole(user.role),
          ),

          const SizedBox(height: 28),

          OutlinedButton.icon(
            onPressed: () {
              _logout(context);
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Sair da conta'),
            ),
          ),
        ],
      ),
    );
  }

  static String _descricaoStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Conta ativa';

      case 'PENDING_EMAIL':
        return 'E-mail pendente';

      case 'BLOCKED':
        return 'Conta bloqueada';

      default:
        return status;
    }
  }

  static String _descricaoRole(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrador';

      case 'USER':
        return 'Usuário';

      default:
        return role;
    }
  }
}

class _CardInformacao extends StatelessWidget {
  const _CardInformacao({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  final IconData icon;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E9EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF102F46)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF71818A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
