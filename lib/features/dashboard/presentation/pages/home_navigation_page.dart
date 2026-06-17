import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_page.dart';
import 'debts_page.dart';
import '../widgets/app_drawer.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class HomeNavigationPage extends StatefulWidget {
  const HomeNavigationPage({super.key});

  @override
  State<HomeNavigationPage> createState() => _HomeNavigationPageState();
}

class _HomeNavigationPageState extends State<HomeNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const DebtsPage(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    final bloc = context.read<DashboardBloc>();
    if (index == 0) {
      final targetMonth = bloc.state is DashboardLoaded
          ? (bloc.state as DashboardLoaded).targetMonth
          : DateTime.now();
      bloc.add(LoadDashboard(targetMonth: targetMonth));
    } else if (index == 1) {
      bloc.add(LoadDebts());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: AppDrawer(
        onItemSelected: _onTabSelected,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              activeIcon: Icon(Icons.calendar_month_rounded, size: 26),
              label: 'Mensal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_late_rounded),
              activeIcon: Icon(Icons.assignment_late_rounded, size: 26),
              label: 'Dívidas',
            ),
          ],
        ),
      ),
    );
  }
}
