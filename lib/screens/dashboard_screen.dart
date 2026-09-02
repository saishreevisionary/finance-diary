import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import 'daily_collection_screen.dart';
import 'loan_statement_screen.dart';
import 'party_list_screen.dart';
import 'payment_history_screen.dart';
import 'dashboard_overview.dart';
import 'reports_screen.dart';
import 'investments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _title = "Finance Diary";

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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Finance Diary',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => Provider.of<FinanceProvider>(context, listen: false).fetchDashboardData(),
          ),
        ],
      ),
      drawer: Drawer(
        width: 300,
        backgroundColor: const Color(0xFFF9FAFB),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Custom High-Fidelity Header
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF4F46E5),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Finance Diary",
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            "Manager Mode",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _drawerItem(
                    title: "Dashboard",
                    icon: Icons.dashboard_rounded,
                    iconColor: const Color(0xFF3B82F6), // Blue
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    title: "Loan Statement (Excel Grid)",
                    icon: Icons.table_chart_rounded,
                    iconColor: const Color(0xFF7C3AED), // Purple
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanStatementScreen()));
                    },
                  ),
                  _drawerItem(
                    title: "All Parties",
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFF10B981), // Emerald Green
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen()));
                    },
                  ),
                  _drawerItem(
                    title: "Billing / Collection",
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFFF59E0B), // Amber
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyCollectionScreen()));
                    },
                  ),
                  _drawerItem(
                    title: "Payment History",
                    icon: Icons.history_rounded,
                    iconColor: const Color(0xFF8B5CF6), // Violet
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
                    },
                  ),
                  _drawerItem(
                    title: "Investments",
                    icon: Icons.savings_rounded,
                    iconColor: const Color(0xFF0D9488), // Teal
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentsScreen()));
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Color(0xFFE5E7EB), height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 12),
                    child: Text(
                      "ANALYTICS",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _drawerItem(
                    title: "Reports",
                    icon: Icons.analytics_rounded,
                    iconColor: const Color(0xFFEC4899), // Pink
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                    },
                  ),
                ],
              ),
            ),
            // Bottom Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.settings_rounded, color: Color(0xFF9CA3AF), size: 22),
                  const SizedBox(width: 12),
                  Text(
                    "Settings",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "v1.0.0",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // We use the DashboardOverview as the 'Home' body
      body: const DashboardOverview(),
    );
  }

  Widget _drawerItem({required String title, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: iconColor.withOpacity(0.1),
          highlightColor: iconColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
