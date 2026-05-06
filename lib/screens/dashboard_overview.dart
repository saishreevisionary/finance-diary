import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../widgets/stat_card.dart';
import 'party_list_screen.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  // We can fetch data here or rely on the parent/shell to verify data access
  // But typically the overview might want to refresh itself or the provider.
  // The provided code had fetch in initState.
  
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currencyFormat = NumberFormat.simpleCurrency(name: 'INR');

    // Return just the content, as the parent Scaffold handles AppBar/Drawer
    return provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Overview",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9, // Taller cards
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        StatCard(
                          title: "Total Parties",
                          value: "${provider.totalParties}",
                          icon: Icons.people,
                          color: Colors.blue,
                          onTap: () {
                             // Switch to Party Tab? 
                             // Since we are decoupling, maybe just push or let user use bottom bar.
                             // For now, simple push is fine or we can remove onTap if redundant.
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen()));
                          },
                        ),
                        StatCard(
                          title: "Total Given",
                          value: currencyFormat.format(provider.totalAmountGiven),
                          icon: Icons.account_balance_wallet,
                          color: Colors.purple,
                        ),
                        StatCard(
                          title: "Today's Due",
                          value: currencyFormat.format(provider.todaysDueAmount),
                          icon: Icons.calendar_today,
                          color: Colors.orange,
                        ),
                        StatCard(
                          title: "Collected Today",
                          value: currencyFormat.format(provider.todaysCollectedAmount),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        StatCard(
                          title: "Pending Count",
                          value: "${provider.pendingPaymentsCount}",
                          icon: Icons.pending_actions,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
  }
}
