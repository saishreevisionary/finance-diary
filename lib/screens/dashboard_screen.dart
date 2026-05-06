import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import 'add_party_screen.dart';
import 'daily_collection_screen.dart';
import 'party_list_screen.dart';
import 'payment_history_screen.dart';
import 'dashboard_overview.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _title = "Finance Diary";

  // Using a map or list to manage screens and their titles
  final List<Widget> _screens = [
    const DashboardOverview(),
    const PartyListScreen(), // Note: PartyListScreen has its own Scaffold. Use with care or refactor.
    const DailyCollectionScreen(),
    const PaymentHistoryScreen(),
    const ReportsScreen(),
  ];
  
  // Refactoring child screens to NOT be Scaffolds if used in a Shell?
  // Current implementations of Screens (PartyList, DailyCollection, etc.) return Scaffold.
  // If we nest Scaffolds, it's okay but we might get double AppBars if not careful.
  // STRATEGY: 
  // We will use the Drawer Model where selecting an item PUSHES the route. 
  // This allows each screen to be independent and have back buttons if needed, 
  // OR we give every screen the same Drawer.
  //
  // BUT: "Go with menu" usually implies a central navigation hub.
  // Let's implement the "Shell" approach but we must remove Scaffolds from children OR hide the shell AppBar.
  // 
  // SIMPLER APPROACH for this specific user request:
  // Return to a single Dashboard Home that has the Drawer. 
  // Clicking an item in Drawer Pushes the new screen.
  // This is standard navigation.
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<FinanceProvider>(context, listen: false).fetchDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    // This is the Main Dashboard Screen with the Drawer
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<FinanceProvider>(context, listen: false).fetchDashboardData(),
          ),
        ],
      ),
      drawer: Drawer(
        elevation: 0,
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                accountName: const Text(
                  "Finance Diary", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                ),
                accountEmail: const Text("Manager"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor, size: 36),
                ),
              ),
              const SizedBox(height: 8),
              _drawerItem(0, "Dashboard", Icons.dashboard_outlined),
              _drawerItem(1, "Parties List", Icons.people_outline, onTap: () {
                 Navigator.pop(context); // Close drawer
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen()));
              }),
              _drawerItem(2, "Billing / Collection", Icons.receipt_long_outlined, onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyCollectionScreen()));
              }),
              _drawerItem(3, "Payment History", Icons.history_outlined, onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
              }),
              _drawerItem(4, "Party Wise Details", Icons.description_outlined, onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen()));
              }),
              const Divider(height: 32, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text("Analytics", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              ),
              _drawerItem(5, "Reports", Icons.analytics_outlined, onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              }),
            ],
          ),
        ),
      ),
      // We use the DashboardOverview as the 'Home' body
      body: const DashboardOverview(),
    );
  }

  Widget _drawerItem(int index, String title, IconData icon, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // highlight logic could be added if we track current index, but simple onTap is fine
        leading: Icon(icon, color: Colors.grey.shade700),
        title: Text(
          title, 
          style: GoogleFonts.outfit(
            fontSize: 16, 
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          )
        ),
        hoverColor: Theme.of(context).primaryColor.withAlpha(10),
        onTap: onTap ?? () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
