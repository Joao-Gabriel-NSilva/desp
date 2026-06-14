import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' show basename;
import '../../data/services/auth_service.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../pages/login_page.dart';
import '../pages/family_page.dart';

class AppDrawer extends StatelessWidget {
  final ValueChanged<int> onItemSelected;

  const AppDrawer({
    super.key,
    required this.onItemSelected,
  });

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 12),
            Text(
              'Sobre o Desp',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desp — Controle Financeiro Premium',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Desenvolvido com Flutter e BLoC para entregar uma experiência moderna, reativa e offline-first com salvamento local via SQLite.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            SizedBox(height: 16),
            Text(
              'Versão: 1.0.0',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.settings_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 12),
            Text(
              'Configurações',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'As configurações do aplicativo estão pré-definidas para o modo escuro automático e persistência local offline de alta velocidade.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Entendi',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final bloc = context.read<DashboardBloc>();
      final repository = bloc.repository;

      final jsonString = await repository.exportData();
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;

      final String? path = await FilePicker.saveFile(
        dialogTitle: 'Exportar Backup',
        fileName: 'desp_backup_$timestamp.json',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Backup exportado com sucesso: ${basename(path)}'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Text('Erro na Exportação',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(
                'Não foi possível exportar os dados: ${e.toString()}',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar',
                    style: TextStyle(color: Color(0xFF6366F1))),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();

        if (context.mounted) {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              title: const Text('Confirmar Importação',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: const Text(
                'Esta ação substituirá permanentemente todos os dados atuais do aplicativo pelo arquivo de backup selecionado. Deseja prosseguir?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white60)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE11D48)),
                  child: const Text('Importar e Substituir'),
                ),
              ],
            ),
          );

          if (confirm == true && context.mounted) {
            final bloc = context.read<DashboardBloc>();

            // Tenta importar e validar os dados
            await bloc.repository.importData(jsonString);

            // Recarrega o estado atualizado
            final targetMonth = (bloc.state is DashboardLoaded)
                ? (bloc.state as DashboardLoaded).targetMonth
                : DateTime.now();
            bloc.add(LoadDashboard(targetMonth: targetMonth));

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup importado com sucesso!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Text('Erro na Importação',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(
              'O arquivo selecionado é inválido ou está corrompido.\n\nDetalhes: ${e.toString()}',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar',
                    style: TextStyle(color: Color(0xFF6366F1))),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 16,
      child: SafeArea(
        child: FutureBuilder<UserProfile?>(
          future: AuthService.instance.getCurrentUser(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final String username = user?.username ?? 'Carregando...';
            final String email = user?.email ?? '';
            final String initials = (username.length >= 2)
                ? username.substring(0, 2).toUpperCase()
                : (username.isNotEmpty ? username[0].toUpperCase() : 'JS');

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF1E293B),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white10, height: 1),

                const SizedBox(height: 16),

                // Navigation Items
                _DrawerItem(
                  icon: Icons.calendar_month_rounded,
                  title: 'Visão Geral Mensal',
                  onTap: () {
                    Navigator.of(context).pop();
                    onItemSelected(0);
                  },
                ),
                _DrawerItem(
                  icon: Icons.assignment_late_rounded,
                  title: 'Dívidas & Pendências',
                  onTap: () {
                    Navigator.of(context).pop();
                    onItemSelected(1);
                  },
                ),
                _DrawerItem(
                  icon: Icons.people_rounded,
                  title: 'Conta Família',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FamilyPage()),
                    );
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(color: Colors.white10, height: 1),
                ),

                // Backup items
                _DrawerItem(
                  icon: Icons.backup_rounded,
                  title: 'Exportar Dados (Backup)',
                  onTap: () {
                    Navigator.of(context).pop();
                    _exportBackup(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_backup_restore_rounded,
                  title: 'Importar Dados (Backup)',
                  onTap: () {
                    Navigator.of(context).pop();
                    _importBackup(context);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(color: Colors.white10, height: 1),
                ),

                // Utility Items
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Configurações',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showSettingsDialog(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Sobre o Desp',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAboutDialog(context);
                  },
                ),
                      ],
                    ),
                  ),
                ),

                // Botão de Logout
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Sair da Conta',
                  onTap: () async {
                    Navigator.of(context).pop(); // fecha drawer
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Desp v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        horizontalTitleGap: 8,
        dense: true,
      ),
    );
  }
}
