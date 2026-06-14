import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';
import '../../data/services/auth_service.dart';
import 'category_helper.dart';

class AddTransactionDialog extends StatefulWidget {
  final Function(Transaction transaction, int? totalInstallments, bool isRecurring) onSave;
  final Transaction? initialTransaction;
  final bool defaultIsPending;

  const AddTransactionDialog({
    super.key,
    required this.onSave,
    this.initialTransaction,
    this.defaultIsPending = false,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  TransactionCategory _selectedCategory = TransactionCategory.food;
  TransactionPaymentMethod _selectedPaymentMethod = TransactionPaymentMethod.pix;
  
  bool _isPending = false;
  bool _isPaid = true;
  bool _isRecurring = false;
  bool _isInstallment = false;
  int _installmentsCount = 2;

  bool _showShareOption = false;
  bool _isShared = false;
  String? _currentUserUid;
  String? _currentUserFamilyId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toString().replaceAll('.', ',');
      _descriptionController.text = tx.description ?? '';
      _selectedType = tx.type;
      _selectedCategory = tx.category;
      _selectedPaymentMethod = tx.paymentMethod;
      _isPending = tx.isPending;
      _isPaid = tx.isPaid;
      _isShared = tx.isShared;
    } else {
      _isPending = widget.defaultIsPending;
      if (_isPending) {
        _isPaid = false;
        _selectedType = TransactionType.expense;
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.instance.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserUid = user.uid;
        _currentUserFamilyId = user.familyId;
        _showShareOption = user.familyId != null;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final double? amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, insira um valor válido.')),
        );
        return;
      }

      // Se for dívida pendente, por padrão ela inicia como NÃO paga
      final finalIsPaid = _isPending ? false : _isPaid;

      final descText = _descriptionController.text.trim();
      final finalDescription = descText.isEmpty ? null : descText;

      final transaction = widget.initialTransaction?.copyWith(
            title: _titleController.text.trim(),
            amount: amount,
            type: _selectedType,
            category: _selectedCategory,
            paymentMethod: _selectedPaymentMethod,
            isPending: _isPending,
            isPaid: finalIsPaid,
            isShared: _isShared,
            ownerId: widget.initialTransaction?.ownerId ?? _currentUserUid,
            familyId: widget.initialTransaction?.familyId ?? _currentUserFamilyId,
            description: finalDescription,
          ) ??
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _titleController.text.trim(),
            amount: amount,
            date: DateTime.now(),
            type: _selectedType,
            category: _selectedCategory,
            paymentMethod: _selectedPaymentMethod,
            isPending: _isPending,
            isPaid: finalIsPaid,
            isShared: _isShared,
            ownerId: _currentUserUid,
            familyId: _currentUserFamilyId,
            description: finalDescription,
          );

      widget.onSave(
        transaction,
        _isInstallment ? _installmentsCount : null,
        _isRecurring,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkSurfaceLight = const Color(0xFF334155);
    final bool isEditing = widget.initialTransaction != null;

    // Ajusta categorias válidas por tipo
    final availableCategories = _selectedType == TransactionType.income
        ? [TransactionCategory.salary, TransactionCategory.other]
        : [
            TransactionCategory.food,
            TransactionCategory.transport,
            TransactionCategory.leisure,
            TransactionCategory.utilities,
            TransactionCategory.subscription,
            TransactionCategory.other
          ];

    // Garante que a categoria selecionada é compatível
    if (!availableCategories.contains(_selectedCategory)) {
      _selectedCategory = availableCategories.first;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de arrastar superior
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEditing ? 'Editar Transação' : 'Nova Transação',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Seletor de Tipo (Receita / Despesa)
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Despesa',
                      isSelected: _selectedType == TransactionType.expense,
                      activeColor: const Color(0xFFF43F5E),
                      icon: Icons.arrow_downward_rounded,
                      onTap: () {
                        setState(() {
                          _selectedType = TransactionType.expense;
                          _selectedCategory = TransactionCategory.food;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TypeButton(
                      label: 'Receita',
                      isSelected: _selectedType == TransactionType.income,
                      activeColor: const Color(0xFF10B981),
                      icon: Icons.arrow_upward_rounded,
                      onTap: () {
                        setState(() {
                          _selectedType = TransactionType.income;
                          _selectedCategory = TransactionCategory.salary;
                          _isPending = false; // receita não pode ser dívida pendente
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Input de Título
              TextFormField(
                controller: _titleController,
                maxLength: 50,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Título (ex: Aluguel, Uber)',
                  labelText: 'Título',
                  counterStyle: TextStyle(color: Colors.white38),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Insira um título';
                  }
                  if (value.trim().length > 50) {
                    return 'O título deve ter no máximo 50 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input de Descrição
              TextFormField(
                controller: _descriptionController,
                maxLength: 500,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Descrição detalhada (opcional)',
                  labelText: 'Descrição',
                  counterStyle: TextStyle(color: Colors.white38),
                ),
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'A descrição deve ter no máximo 500 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input de Valor
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: '0,00',
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  prefixStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Insira um valor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Seletor de Forma de Pagamento
              Text(
                'Meio de Pagamento',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TransactionPaymentMethod.values.map((method) {
                  final bool isMethSelected = _selectedPaymentMethod == method;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedPaymentMethod = method),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isMethSelected
                                ? theme.primaryColor.withValues(alpha: 0.15)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMethSelected
                                  ? theme.primaryColor
                                  : darkSurfaceLight.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                method.icon,
                                color: isMethSelected ? theme.primaryColor : Colors.white60,
                                size: 16,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                method.namePt,
                                style: TextStyle(
                                  color: isMethSelected ? Colors.white : Colors.white60,
                                  fontSize: 10,
                                  fontWeight: isMethSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Switch Compartilhar com a Família (apenas se fizer parte de uma família)
              if (_showShareOption) ...[
                SwitchListTile(
                  title: const Text('Compartilhar com a Família'),
                  subtitle: const Text('Disponibiliza esta transação para todos os membros.'),
                  value: _isShared,
                  activeThumbColor: theme.primaryColor,
                  onChanged: (val) => setState(() => _isShared = val),
                ),
                const SizedBox(height: 10),
              ],

              // Controles extras para despesa
              if (_selectedType == TransactionType.expense) ...[
                // Switch Dívida Pendente
                SwitchListTile(
                  title: const Text('Dívida Pendente em Aberto'),
                  subtitle: const Text('Exibe na aba Dívidas fora do fluxo mensal principal.'),
                  value: _isPending,
                  activeThumbColor: const Color(0xFFF43F5E),
                  onChanged: (val) {
                    setState(() {
                      _isPending = val;
                      if (val) {
                        _isRecurring = false;
                        _isInstallment = false;
                        _isPaid = false;
                      }
                    });
                  },
                ),
                if (!_isPending) ...[
                  // Switch Pago
                  SwitchListTile(
                    title: const Text('Despesa já quitada/paga?'),
                    value: _isPaid,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _isPaid = val),
                  ),
                  if (!isEditing) ...[
                    // Switch Recorrência
                    SwitchListTile(
                      title: const Text('Despesa Recorrente'),
                      subtitle: const Text('Repetir todo mês de forma contínua.'),
                      value: _isRecurring,
                      activeThumbColor: theme.primaryColor,
                      onChanged: (val) {
                        setState(() {
                          _isRecurring = val;
                          if (val) _isInstallment = false;
                        });
                      },
                    ),
                    // Switch Parcelamento
                    SwitchListTile(
                      title: const Text('Parcelar Compra'),
                      subtitle: const Text('Dividir valor em parcelas mensais.'),
                      value: _isInstallment,
                      activeThumbColor: Colors.amber,
                      onChanged: (val) {
                        setState(() {
                          _isInstallment = val;
                          if (val) _isRecurring = false;
                        });
                      },
                    ),
                    if (_isInstallment) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Row(
                          children: [
                            const Text('Número de Parcelas: ', style: TextStyle(color: Colors.white70)),
                            Expanded(
                              child: Slider(
                                value: _installmentsCount.toDouble(),
                                min: 2,
                                max: 24,
                                divisions: 22,
                                label: '$_installmentsCount',
                                activeColor: Colors.amber,
                                onChanged: (val) => setState(() => _installmentsCount = val.round()),
                              ),
                            ),
                            Text('$_installmentsCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ],
              const SizedBox(height: 20),

              // Grid de Categorias
              Text(
                'Selecione a Categoria',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: availableCategories.length,
                itemBuilder: (context, index) {
                  final cat = availableCategories[index];
                  final isCatSelected = _selectedCategory == cat;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCatSelected
                            ? cat.color.withValues(alpha: 0.2)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCatSelected
                              ? cat.color
                              : darkSurfaceLight.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat.icon,
                            color: cat.color,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.namePt,
                            style: TextStyle(
                              color: isCatSelected ? Colors.white : Colors.white60,
                              fontSize: 12,
                              fontWeight: isCatSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Botão de Salvar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    isEditing ? 'Salvar Alterações' : 'Adicionar Transação',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final IconData icon;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkSurfaceLight = const Color(0xFF334155);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : darkSurfaceLight.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
