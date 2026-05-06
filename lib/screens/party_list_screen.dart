import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import 'add_party_screen.dart';
import 'party_details_screen.dart';

class PartyListScreen extends StatelessWidget {
  const PartyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("All Parties")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPartyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: provider.parties.length,
        itemBuilder: (context, index) {
          final party = provider.parties[index];
          final balance = provider.getBalance(party);
          // Status: Pending if Balance > 0, Paid if Balance <= 0
          // User asked for "Active / Completed". Active = Balance > 0.
          final isActive = balance > 0;
          final status = isActive ? "Active" : "Completed";
          final statusColor = isActive ? Colors.orange : Colors.green;

          return Container(
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.grey.shade200),
               boxShadow: [
                 BoxShadow(
                   color: Colors.grey.withAlpha(20),
                   blurRadius: 10,
                   offset: const Offset(0, 4),
                 ),
               ],
             ),
             child: Material(
               color: Colors.transparent,
               child: InkWell(
                 borderRadius: BorderRadius.circular(16),
                 onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PartyDetailsScreen(party: party)),
                   );
                 },
                 child: Padding(
                   padding: const EdgeInsets.all(16),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.blue.withAlpha(10),
                           shape: BoxShape.circle,
                         ),
                         child: Text(
                           party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(
                                   party.name, 
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                 ),
                                 Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                                ),
                               ],
                             ),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                  Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                   decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                   ),
                                   child: Text(party.collectionType.name.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                 ),
                                 const SizedBox(width: 12),
                                 Text(
                                   "Due: ${NumberFormat.simpleCurrency(name: 'INR').format(party.totalPayable)}",
                                   style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 8),
                             Text(
                               "Balance: ${NumberFormat.simpleCurrency(name: 'INR').format(balance)}",
                               style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 15),
                             ),
                           ],
                         ),
                       ),
                       IconButton(
                         icon: Icon(Icons.edit, size: 20, color: Colors.grey.shade400),
                         onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddPartyScreen(party: party)),
                           );
                         },
                       ),
                     ],
                   ),
                 ),
               ),
             ),
          );
        },
      ),
    );
  }
}
