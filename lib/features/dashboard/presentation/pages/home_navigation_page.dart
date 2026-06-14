import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'debts_page.dart';
import '../widgets/app_drawer.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: AppDrawer(
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
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
