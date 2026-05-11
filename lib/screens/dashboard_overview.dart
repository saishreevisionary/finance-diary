import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import '../models/company.dart';
import '../widgets/stat_card.dart';
import 'party_list_screen.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    return provider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              await provider.fetchDashboardData();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Dashboard",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Row(
                      children: [
                        if (provider.currentCompany != null)
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5), size: 22),
                            tooltip: "Edit Selected Company",
                            onPressed: () => _showEditCompanyDialog(context, provider, provider.currentCompany!),
                          ),
                        IconButton(
                          icon: const Icon(Icons.add_business_rounded, color: Color(0xFF4F46E5), size: 28),
                          tooltip: "Create Company",
                          onPressed: () => _showCreateCompanyDialog(context, provider),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Horizontal list of companies
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: provider.companies.length,
                    itemBuilder: (context, index) {
                      final company = provider.companies[index];
                      final isSelected = provider.currentCompany?.id == company.id;
                      return GestureDetector(
                        onTap: () => provider.selectCompany(company),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                            border: isSelected
                                ? null
                                : Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 18,
                                  color: isSelected ? Colors.white : const Color(0xFF4F46E5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  company.name,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected ? Colors.white : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Hero Card for Total Given
                _buildHeroCard(context, provider, currencyFormat),
                const SizedBox(height: 32),
                Text(
                  "Quick Stats",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                // Stat Cards Row 1
                Row(
                  children: [
                    Expanded(
                      child: _buildConstrainedStatCard(
                        StatCard(
                          title: "Today's Due",
                          value: currencyFormat.format(provider.todaysDueAmount),
                          icon: Icons.calendar_today_rounded,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildConstrainedStatCard(
                        StatCard(
                          title: "Collected Today",
                          value: currencyFormat.format(provider.todaysCollectedAmount),
                          icon: Icons.check_circle_rounded,
                          color: Colors.green.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stat Cards Row 2
                Row(
                  children: [
                    Expanded(
                      child: _buildConstrainedStatCard(
                        StatCard(
                          title: "Pending Count",
                          value: "${provider.pendingPaymentsCount}",
                          icon: Icons.pending_actions_rounded,
                          color: Colors.red.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildConstrainedStatCard(
                        StatCard(
                          title: "Total Parties",
                          value: "${provider.totalParties}",
                          icon: Icons.people_alt_rounded,
                          color: Colors.blue.shade500,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyListScreen()));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
  }

  // Helper to ensure StatCard looks good in a Row (which gives unconstrained height)
  Widget _buildConstrainedStatCard(Widget child) {
    return SizedBox(
      height: 150, // Fixed height for consistent look in rows
      child: child,
    );
  }

  Widget _buildHeroCard(BuildContext context, FinanceProvider provider, NumberFormat format) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount Given",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.show_chart_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Live",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              format.format(provider.totalAmountGiven),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat("Due Today", format.format(provider.todaysDueAmount)),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildMiniStat("Collected", format.format(provider.todaysCollectedAmount)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showCreateCompanyDialog(BuildContext context, FinanceProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "Create Company",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter the name of your new finance company to keep its data separated.",
                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Company Name",
                  hintText: "e.g., Company A, Company B",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  await provider.createCompany(name);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Company '$name' created successfully!")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF4F46E5),
              ),
              child: Text("Create", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  void _showEditCompanyDialog(BuildContext context, FinanceProvider provider, Company company) {
    final controller = TextEditingController(text: company.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "Edit Company",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Update the name of '${company.name}'.",
                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Company Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty && name != company.name) {
                  Navigator.pop(context);
                  final updated = Company(
                    id: company.id,
                    name: name,
                    createdAt: company.createdAt,
                  );
                  await provider.updateCompany(updated);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Company name updated successfully!")),
                    );
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF4F46E5),
              ),
              child: Text("Update", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
