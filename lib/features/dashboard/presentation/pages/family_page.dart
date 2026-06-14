import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/family_service.dart';
import '../../domain/entities/user_profile.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final _familyNameController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _formCreateKey = GlobalKey<FormState>();
  final _formInviteKey = GlobalKey<FormState>();
  
  UserProfile? _localUser;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalUser();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalUser() async {
    final user = await AuthService.instance.getCurrentUser();
    setState(() {
      _localUser = user;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF43F5E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _createFamily() async {
    if (!_formCreateKey.currentState!.validate()) return;
    setState(() => _isActionLoading = true);

    try {
      await FamilyService.instance.createFamily(_familyNameController.text);
      _familyNameController.clear();
      _showSuccess('Família criada com sucesso!');
      await _loadLocalUser();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _sendInvite() async {
    if (!_formInviteKey.currentState!.validate()) return;
    setState(() => _isActionLoading = true);

    try {
      await FamilyService.instance.sendInvitation(_inviteEmailController.text);
      _inviteEmailController.clear();
      _showSuccess('Convite enviado com sucesso!');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _acceptInvite(String inviteId, String familyId) async {
    setState(() => _isActionLoading = true);
    try {
      await FamilyService.instance.acceptInvitation(inviteId, familyId);
      _showSuccess('Convite aceito com sucesso!');
      await _loadLocalUser();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _declineInvite(String inviteId) async {
    setState(() => _isActionLoading = true);
    try {
      await FamilyService.instance.declineInvitation(inviteId);
      _showSuccess('Convite recusado.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _confirmLeaveFamily() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E)),
            SizedBox(width: 12),
            Text('Sair da Família', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Deseja realmente sair do grupo familiar? Suas transações compartilhadas continuarão no grupo, mas você deixará de ter acesso aos dados dos outros membros.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isActionLoading = true);
      try {
        await FamilyService.instance.leaveFamily();
        _showSuccess('Você saiu da família.');
        await _loadLocalUser();
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirebase = AuthService.instance.isFirebaseAvailable;

    if (_localUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (!isFirebase) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Conta Família', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Indisponível',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A funcionalidade de Conta Família requer uma conexão ativa com a internet e integração com o Firebase configurada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Conta Família', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(_localUser!.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting && !userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
              }

              final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
              final String? familyId = userData?['familyId'] as String?;

              if (familyId == null || familyId.isEmpty) {
                return _buildNoFamilyView(context);
              }

              return _buildFamilyActiveView(context, familyId);
            },
          ),
          if (_isActionLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
            ),
        ],
      ),
    );
  }

  Widget _buildNoFamilyView(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner explicativo da conta família
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 48, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gerencie finanças juntos',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crie um grupo familiar para compartilhar despesas e receitas em tempo real com sua família.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Seção de Criação de Família
          const Text(
            'Criar Nova Família',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
            ),
            child: Form(
              key: _formCreateKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _familyNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ex: Família Silva',
                      labelText: 'Nome do Grupo Familiar',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Insira um nome para o grupo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _createFamily,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Criar Família', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Seção de Convites Pendentes
          const Text(
            'Convites Recebidos',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FamilyService.instance.getPendingInvitationsStream(_localUser!.email),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ));
              }

              final invites = snapshot.data ?? [];
              if (invites.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.02), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.mail_outline_rounded, size: 40, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhum convite pendente',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invites.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  final String fromEmail = invite['fromEmail'] as String? ?? 'Desconhecido';
                  final String familyId = invite['familyId'] as String? ?? '';
                  final String inviteId = invite['id'] as String? ?? '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded, color: Color(0xFF6366F1), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fromEmail,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Convidou você para fazer parte de seu grupo familiar.',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _declineInvite(inviteId),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white24),
                                  foregroundColor: Colors.white60,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Recusar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _acceptInvite(inviteId, familyId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Aceitar', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyActiveView(BuildContext context, String familyId) {
    final theme = Theme.of(context);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: FamilyService.instance.getFamilyInfoStream(familyId),
      builder: (context, familySnapshot) {
        if (familySnapshot.connectionState == ConnectionState.waiting && !familySnapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        final familyData = familySnapshot.data;
        final familyName = familyData?['name'] as String? ?? 'Minha Família';

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Card Principal da Família
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grupo Familiar Ativo',
                    style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    familyName,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Membros da Família
            const Text(
              'Membros',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<UserProfile>>(
              stream: FamilyService.instance.getFamilyMembersStream(familyId),
              builder: (context, membersSnapshot) {
                if (membersSnapshot.connectionState == ConnectionState.waiting && !membersSnapshot.hasData) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ));
                }

                final members = membersSnapshot.data ?? [];
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final String memberInitials = member.username.length >= 2
                          ? member.username.substring(0, 2).toUpperCase()
                          : member.username.isNotEmpty ? member.username[0].toUpperCase() : 'M';
                      
                      final isMe = member.uid == _localUser!.uid;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E293B),
                          child: Text(
                            memberInitials,
                            style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          isMe ? '${member.username} (Você)' : member.username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          member.email,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Enviar Convite
            const Text(
              'Convidar Membro',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.5),
              ),
              child: Form(
                key: _formInviteKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _inviteEmailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'exemplo@email.com',
                        labelText: 'E-mail do Membro',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Insira o e-mail do membro';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Insira um e-mail válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _sendInvite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Enviar Convite', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Sair da Família
            Center(
              child: OutlinedButton.icon(
                onPressed: _confirmLeaveFamily,
                icon: const Icon(Icons.exit_to_app_rounded, size: 20),
                label: const Text('Sair do Grupo Familiar', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF43F5E),
                  side: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
